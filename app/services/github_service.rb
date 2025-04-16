require 'httparty'
require 'dotenv/load'

class GitHubService
  include HTTParty
  base_uri 'https://api.github.com'

  def initialize
    @headers = {
      "Accept" => "application/vnd.github+json",
      "Authorization" => "Bearer #{ENV['GITHUB_TOKEN']}",
      "X-GitHub-Api-Version" => "2022-11-28"
    }
    @org = ENV['ORGANIZATION_NAME']
  end


  def fetch_members
    response = self.class.get("/orgs/#{@org}/members", headers: @headers)

    if response.success?
      response.each do |member|
        Employee.find_or_create_by(github_id: member["id"]) do |e|
          e.name = member["login"]
        end
      end
      puts "Members imported successfully."
    else
      puts "Error fetching members: #{response.code} - #{response.message}"
    end
  end

  def fetch_repos
    response = self.class.get("/orgs/#{@org}/repos", headers: @headers)
  
    if response.success?
      repo_names = response.parsed_response.map { |repo| repo["name"] }
      # puts "#{repo_names}"
      return repo_names
    else
      puts "Error fetching repos: #{response.code} - #{response.message}"
      return []
    end
  end

  def fetch_prs
    repos = fetch_repos
  
    repos.each do |repo|
      response = self.class.get("/repos/#{@org}/#{repo}/pulls", headers: @headers, query: { state: 'all' })
      # puts response.size
      # puts repo
  
      if response.success?
        response.parsed_response.each do |pull|
          pr_number = pull["number"]
          pr_details = self.class.get("/repos/#{@org}/#{repo}/pulls/#{pr_number}", headers: @headers)
  
          next unless pr_details.success?
  
          pr_data = pr_details.parsed_response

          preq = PullRequest.find_or_initialize_by(pr_id: pr_data["id"])

          preq.assign_attributes(
            pr_created_at: pr_data["created_at"],
            pr_closed_at: pr_data["closed_at"],
            pr_merged_at: pr_data["merged_at"],
            status: pr_data["state"],
            review_counts: pr_data["review_comments"],
            pr_node_id: pr_data["node_id"],
            LOC: pr_data["additions"].to_i + pr_data["deletions"].to_i
          )
          preq.save!
          fetch_comments_for_pr(pr_data["id"], pr_data["review_comments_url"], pr_data["commits_url"])
          fetch_dev_met(pr_data["id"], repo, pr_data["commits_url"])
        end
      else
        puts "Error fetching PRs for #{repo}: #{response.code} - #{response.message}"
      end
    end
    # puts "Pull requests fetched and stored successfully."
  end

  # def fetch_comments_for_pr(pr_id, comments_url, commits_url)
  #   comments_response = self.class.get(comments_url, headers: @headers)
  #   commits_response = self.class.get(commits_url, headers: @headers)
  
  #   return unless comments_response.success? && commits_response.success?
  
  #   commits = commits_response.parsed_response  
  #   comments_response.parsed_response.each do |comment|
  #     comment_time = Time.parse(comment["created_at"])
  #     next_commit_time = nil

  #     commits.each do |commit|
  #       commit_time = Time.parse(commit["commit"]["author"]["date"])
  #       if commit_time > comment_time
  #         next_commit_time = commit_time
  #         break
  #       end
  #     end
  
  #     review = Review.find_or_initialize_by(review_id: comment["id"])
  
  #     review.assign_attributes(
  #       review_node_id: comment["node_id"],
  #       pr_id: pr_id,
  #       github_id: comment["user"]["id"],
  #       rev_created_at: comment_time,
  #       next_commit_at: next_commit_time,
  #     )
  #     review.save!
  #   end
  # end 

  def fetch_comments_for_pr(pr_id, comments_url, commits_url)
    return unless PullRequest.exists?(pr_id: pr_id)
  
    comments_response = self.class.get(comments_url, headers: @headers)
    commits_response = self.class.get(commits_url, headers: @headers)
  
    return unless comments_response.success? && commits_response.success?
  
    commits = commits_response.parsed_response
  
    comments_response.parsed_response.each do |comment|
      github_user = comment["user"]
      next unless github_user
  
      github_id = github_user["id"]
      next unless Employee.exists?(github_id: github_id)
  
      comment_time = Time.parse(comment["created_at"])
      next_commit_time = commits.map { |c| Time.parse(c["commit"]["author"]["date"]) }.find { |t| t > comment_time }
  
      review = Review.find_or_initialize_by(review_id: comment["id"])
      review.assign_attributes(
        review_node_id: comment["node_id"],
        pr_id: pr_id,
        github_id: github_id,
        rev_created_at: comment_time,
        next_commit_at: next_commit_time
      )
      review.save!
    end
  end
  
  def fetch_dev_met(pr_id, repo, commits_url)
    response = self.class.get(commits_url, headers: @headers)
    return unless response.success?
  
    commits = response.parsed_response
  
    commits.each do |commit|
      sha = commit["sha"]
      commit_detail_url = "/repos/#{@org}/#{repo}/commits/#{sha}"
      commit_response = self.class.get(commit_detail_url, headers: @headers)
  
      next unless commit_response.success?
  
      commit_data = commit_response.parsed_response
  
      github_id = commit_data["author"]&.dig("id")
      next if github_id.nil?
  
      employee = Employee.find_by(github_id: github_id)
      pull_request = PullRequest.find_by(pr_id: pr_id)
  
      puts "Employee: #{employee&.inspect}"
      puts "PullRequest: #{pull_request&.inspect}"
  
      next if employee.nil? || pull_request.nil?
  
      loc = commit_data["stats"]["total"].to_i
      next if DeveloperMatrix.exists?(pr_id: pull_request.pr_id, github_id: employee.github_id)
  
      DeveloperMatrix.create!(
        pr_id: pull_request.pr_id,
        github_id: employee.github_id,
        LOC: loc
      )
    end
  end
  
  

  # def fetch_user_id(login)
  #   return nil if login.nil?
  
  #   response = self.class.get("https://api.github.com/users/#{login}", headers: @headers)
  #   response.success? ? response.parsed_response["id"] : nil
  # end
end
