class OrgdatafetchService
  include HTTParty
  base_uri 'https://api.github.com'

  def initialize
    @headers = {
      "Accept" => "application/vnd.github+json",
      "Authorization" => "Bearer #{Rails.application.credentials.github[:token]}",
      "X-GitHub-Api-Version" => "2022-11-28"
    }
    @org = Rails.application.credentials.github[:org]
    @repo = Rails.application.credentials.github[:repo]
    @cutoff_date = Time.current - 1.year
  end

  def fetch_prs
    page = 1
    while true do
      response = self.class.get(
        "/repos/#{@org}/#{@repo}/pulls",
        headers: @headers,
        query: { state: 'all', per_page: 100, page: page }
      )

      if !response.success?
        break
      end

      prs = response.parsed_response
      if prs.empty?
        break
      end

      prs.each do |pull|
        created_at = Time.parse(pull["created_at"])
        if created_at < @cutoff_date
          return
        end

        pr_details = self.class.get("/repos/#{@org}/#{@repo}/pulls/#{pull['number']}", headers: @headers)

        if !pr_details.success?
          next
        end

        pr_data = pr_details.parsed_response

        author = pr_data["user"]
        if !author || !author["id"]
          next
        end

        Employee.find_or_create_by!(github_id: author["id"]) do |e|
          e.name = author["login"]
        end

        pull_request = PullRequest.find_or_initialize_by(pr_id: pr_data["id"])
        pull_request.assign_attributes(
          pr_created_at: pr_data["created_at"],
          pr_closed_at: pr_data["closed_at"],
          pr_merged_at: pr_data["merged_at"],
          status: pr_data["state"],
          review_counts: pr_data["review_comments"],
          pr_node_id: pr_data["node_id"],
          LOC: pr_data["additions"].to_i + pr_data["deletions"].to_i
        )
        pull_request.save!

        fetch_comments_for_pr(pr_data["id"], pr_data["review_comments_url"], pr_data["commits_url"])
        fetch_dev_met(pr_data["id"], pr_data["commits_url"])
      end

      page += 1
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
      if !github_user || !github_user["id"]
        next
      end

      Employee.find_or_create_by!(github_id: github_user["id"]) do |e|
        e.name = github_user["login"]
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
        github_id: github_user["id"],
        rev_created_at: comment_time,
        next_commit_at: next_commit_time
      )
      review.save!
    end
  end

  def fetch_dev_met(pr_id, commits_url)
    response = self.class.get(commits_url, headers: @headers)
    if !response.success?
      return
    end

    commits = response.parsed_response

    commits.each do |commit|
      sha = commit["sha"]
      commit_response = self.class.get("/repos/#{@org}/#{@repo}/commits/#{sha}", headers: @headers)
      if !commit_response.success?
        next
      end

      commit_data = commit_response.parsed_response
      github_id = commit_data["author"]["id"]

      Employee.find_or_create_by!(github_id: github_id) do |e|
        e.name = commit_data["author"]["login"]
      end

      pull_request = PullRequest.find_by(pr_id: pr_id)
      if !pull_request
        next
      end

      if DeveloperMatrix.exists?(pr_id: pull_request.pr_id, github_id: github_id)
        next
      end

      DeveloperMatrix.create!(
        pr_id: pull_request.pr_id,
        github_id: github_id,
        LOC: commit_data["stats"]["total"].to_i
      )
    end
  end
end