# Scroll to any element/section
# @param element [Capybara::Node::Element, SitePrism::Section]

require "facets"

def load_all_apps
  @bo = BackOfficeApp.new
  @fo = FrontOfficeApp.new
  @journey = JourneyApp.new
end

def mocking_enabled?
  # Simple helper to check if mocking is currently enabled.
  # It is based on the fact that the mock gem uses URL constraints,
  # hence when we hit a mocking valid URL, if we receive a 404 response back,
  # we can assume that mocking is disabled
  uri = URI.parse(Quke::Quke.config.custom["urls"]["mock_enabled"])

  if ENV["WCRS_PROXY"].nil?
    # using an instance variable so that we make the request to the mocking
    # endpoint only once
    @_mocking_enabled_response ||= Net::HTTP.get_response(uri)
  else
    # Adding proxy for http request
    proxy_uri = URI.parse(ENV["WCRS_PROXY"])
    http = Net::HTTP.new(uri.hostname, uri.port, proxy_uri.host, proxy_uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    @_mocking_enabled_response ||= http.request(request)
  end

  return false if @_mocking_enabled_response.to_s.include?("HTTPNotFound")

  true
end

def sign_in_to_front_office(email)
  url = URI.parse(current_url).to_s
  visit(Quke::Quke.config.custom["urls"]["front_office_sign_in"]) if url.not.include? "fo/users/sign_in"
  return if page.has_text?("Signed in as " + email)

  @fo.front_office_sign_in_page.submit(
    email: email,
    password: ENV["WCRS_DEFAULT_PASSWORD"]
  )
end

def sign_in_to_back_office(user, force = true)
  # If force == true then this forces signout regardless of the user's type.

  # Check whether user is already logged in by visiting root page:
  visit(Quke::Quke.config.custom["urls"]["back_office"])

  # Return if already logged in as that user.
  # This relies on the user property name in .config.yml being the same as the start of the user's email address:
  return if page.text.include?("Signed in as") && !force
  return if page.text.include? "Signed in as #{user}"

  # If user is already signed in as a different user, then sign them out:
  heading = @journey.standard_page.heading.text
  sign_out_of_back_office if heading != "Sign in"

  # Then sign in as the correct user:
  @bo.sign_in_page.submit(
    # user must match the user headings in .config.yml:
    email: Quke::Quke.config.custom["accounts"][user]["username"],
    password: ENV["WCRS_DEFAULT_PASSWORD"]
  )
end

def sign_out_of_back_office
  # Check not already signed out
  visit(Quke::Quke.config.custom["urls"]["back_office"])
  heading = @journey.standard_page.heading.text

  # Bypass if already logged out:
  return if heading != "Waste carriers registrations"

  @bo.dashboard_page.sign_out_link.click
  expect(@journey.standard_page.heading).to have_text("Sign in")
end

def scroll_to(element)
  element = element.root_element if element.respond_to?(:root_element)
  Capybara.evaluate_script <<-SCRIPT
       function() {
         var element = document.evaluate('#{element.path}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
         window.scrollTo(0, element.getBoundingClientRect().top + pageYOffset - 200);
       }();
  SCRIPT
end

def click(node)
  if Capybara.current_driver == :phantomjs
    node.trigger("click")
  else
    node.click
  end
end

def try(number_of_times)
  count = 0
  item_of_interest = nil
  until !item_of_interest.nil? || count == number_of_times
    item_of_interest = yield
    sleep 10
    count += 1
  end
end

def generate_email
  @email_address = "#{rand(100_000_000)}@example.com"
end

def look_into_paginated_content_for(text)
  # Start from first page. Look for the known text on page.
  # If it's not there, click Next and look again.
  # Break after 30 pages.
  find_link("« First").click if page.has_text?("« First")

  30.times do
    break if page.has_text?(text)

    find_link("Next ›").click
  end
end

def next_year
  time = Time.new
  year = time.strftime "%y"
  year.to_i + 1
end

def retrieve_email_containing(search_terms)
  # Search for and return email text containing all the items from the search_terms array.
  # Assumes that the user has already navigated to the correct front or back office email page.
  email_was_found = @journey.last_message_page.check_message_for_text(search_terms)
  return @journey.last_message_page.text if email_was_found

  "Email not found"
end

def visit_last_message_page_for(app)
  last_email_address = if app == "bo"
                         "last_email_bo"
                       else
                         "last_email_fo"
                       end
  visit Quke::Quke.config.custom["urls"][last_email_address]
end

def password_reset_link(account_email)
  # Get password reset email:
  visit(Quke::Quke.config.custom["urls"]["last_email_fo"])
  reset_email_text = retrieve_email_containing([account_email]).to_s
  expect(reset_email_text).to have_text("Someone has requested a link to change your password")

  # Get the password reset link from the email text:
  # rubocop:disable Style/RedundantRegexpEscape
  reset_password_link = reset_email_text.match(/.*href\=\\"(.*)\\">Change.*/)[1].to_s
  # rubocop:enable Style/RedundantRegexpEscape
  puts "Link to reset password is: " + reset_password_link

  reset_password_link
end
