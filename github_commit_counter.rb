require 'net/http'
require 'json'
require 'date'

def fetch(url, token)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri, {
    'Authorization' => "token #{token}",
    'User-Agent' => 'Ruby'
  })
  response = http.request(request)
  JSON.parse(response.body)
end

def count_user_commits(username, token)
  base_url = "https://api.github.com"
  end_date = DateTime.now
  start_date = end_date - 30

  # Fetch all repositories for the authenticated user
  page = 1
  all_repos = []
  loop do
    puts "Fetching repos for #{username}, page #{page}..."
    repos_url = "#{base_url}/user/repos?page=#{page}&per_page=100"
    repos = fetch(repos_url, token)
    break if repos.empty?

    all_repos.concat(repos)
    page += 1
  end

  commit_count = 0
  lines_added = 0
  lines_removed = 0

  # Iterate over repositories
  all_repos.each do |repo|
    puts "Fetching commits for #{repo['name']}..."
    branches_url = "#{repo['url']}/branches"
    branches = fetch(branches_url, token)

    branches.each do |branch|
      puts "Fetching commits for #{repo['name']}, branch #{branch['name']}..."
      commits_url = "#{repo['url']}/commits?since=#{start_date.iso8601}&sha=#{branch['name']}"

      # Fetch commits
      commits = fetch(commits_url, token)

      # Count commits, lines added, and lines removed within the last 30 days
      commits.each do |commit|
        commit_date = DateTime.parse(commit['commit']['committer']['date'])
        if commit_date.between?(start_date, end_date)
          commit_count += 1

          commit_detail = fetch(commit['url'], token)
          lines_added += commit_detail['stats']['additions']
          lines_removed += commit_detail['stats']['deletions']
        end
      end
    end
  end

  [commit_count, lines_added, lines_removed]
end

# Replace 'your_github_token' with your actual GitHub token
# Replace 'username' with the GitHub username you want to check
commits, additions, deletions = count_user_commits('username', 'your_github_token')
puts "Commits: #{commits}, Lines added: #{additions}, Lines removed: #{deletions}"
