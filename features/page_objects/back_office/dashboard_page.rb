require_relative "sections/govuk_banner"

class DashboardPage < SitePrism::Page
  set_url(Quke::Quke.config.custom["urls"]["back_office"])

  section(:govuk_banner, GovukBanner, GovukBanner::SELECTOR)
  element(:heading, ".heading-large")
  element(:sign_out_link, "a[href*='/bo/users/sign_out']")
  element(:content, "#content")

  element(:flash_message, ".flash-message")

  element(:search_term, "#term")
  element(:submit_button, ".button")
  element(:new_reg_link, "a[href*='/bo/ad-privacy-policy']")

  element(:results_table, "table")
  elements(:reg_details_links, "a[href*='/registrations/CBD']")
  elements(:new_reg_details_links, "a[href*='/new-registrations/")
  elements(:transient_reg_details_links, "a[href*='/renewing-registrations/CBD']")

  sections :results, "table tbody tr" do
    element(:registration_number, "td:nth-child(1)")
    element(:status, "td:nth-child(3)")
    element(:actions, "td:nth-child(5)")
  end

  def submit(args = {})
    search_term.set(args[:search_term]) if args.key?(:search_term)
    submit_button.click
  end

  def view_reg_details(args = {})
    submit(search_term: args[:search_term])
    i = 0
    while i < 5 && reg_details_links.nil?
      sleep(1)
      i += 1
      puts i
    end
    reg_details_links[0].click
  end

  def view_new_reg_details(args = {})
    submit(search_term: args[:search_term])
    i = 0
    while i < 5 && new_reg_details_links.nil?
      sleep(1)
      i += 1
      puts i
    end
    new_reg_details_links[0].click
  end

  def view_transient_reg_details(args = {})
    submit(search_term: args[:search_term])
    transient_reg_details_links[0].click
  end
end
