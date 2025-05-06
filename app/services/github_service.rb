class GithubService
  include HTTParty
  base_uri 'https://api.github.com'

  def initialize
    @headers = {
      "Accept" => "application/vnd.github+json",
      "Authorization" => "Bearer #{Rails.application.credentials.github[:token]}",
      "X-GitHub-Api-Version" => "2022-11-28"
    }
    @org = Rails.application.credentials.github[:org]
  end


  def fetch_members
    response = self.class.get("/orgs/#{@org}/members", headers: @headers)

    if response.success?
      response.each do |member|
        Employee.find_or_create_by(github_id: member["id"]) do |e|
          e.name = member["login"]
        end
      end
    else
      puts "Error fetching members: #{response.code} - #{response.message}"
    end
  end

  def fetch_repos
    response = self.class.get("/orgs/#{@org}/repos", headers: @headers)
  
    if response.success?
      repo_names = []
      response.each do |repo|
        repo_names.append(repo["name"])
      end
      puts repo_names
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
  
      if response.success?
        response.parsed_response.each do |pull|
          pr_number = pull["number"]
          pr_details = self.class.get("/repos/#{@org}/#{repo}/pulls/#{pr_number}", headers: @headers)
          if !pr_details.success?
            next
          end  
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
  end

  def fetch_comments_for_pr(pr_id, comments_url, commits_url)
    if !PullRequest.exists?(pr_id: pr_id)
      return
    end
  
    comments_response = self.class.get(comments_url, headers: @headers)
    commits_response = self.class.get(commits_url, headers: @headers)
  
    if !comments_response.success? || !commits_response.success?
      return
    end
  
    commits = commits_response.parsed_response
  
    comments_response.parsed_response.each do |comment|
      github_user = comment["user"]

      if !github_user
        next
      end
  
      github_id = github_user["id"]
      if !Employee.exists?(github_id: github_id)
        next
      end
  
      comment_time = Time.parse(comment["created_at"])

      next_commit_time = Time.new
      commits.each do |commit|
        commit_time = Time.parse(commit["commit"]["author"]["date"])
        if commit_time >= comment_time
          next_commit_time = commit_time
        end
      end
  
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

      commit_response = self.class.get("/repos/#{@org}/#{repo}/commits/#{sha}", headers: @headers)
  
      if !commit_response.success?
        next
      end
  
      commit_data = commit_response.parsed_response
  
      author = commit_data["author"]
      if author.nil?
        next
      end
      github_id = author["id"]
  
      employee = Employee.find_by(github_id: github_id)
      pull_request = PullRequest.find_by(pr_id: pr_id)
  
      puts "Employee: #{employee&.inspect}"
      puts "PullRequest: #{pull_request&.inspect}"
  
      if employee.nil? || pull_request.nil?
        next
      end
  
      loc = commit_data["stats"]["total"].to_i

      if DeveloperMatrix.exists?(pr_id: pull_request.pr_id, github_id: employee.github_id)
        next
      end
  
      DeveloperMatrix.create!(
        pr_id: pull_request.pr_id,
        github_id: employee.github_id,
        LOC: loc
      )
    end
  end
end