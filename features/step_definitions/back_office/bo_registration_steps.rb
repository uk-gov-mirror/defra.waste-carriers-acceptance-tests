Given("I register an upper tier {string} from the back office") do |organisation_type|
  @organisation_type = organisation_type
  @app = "bo"
  @reg_type = :new_registration
  @tier = "upper"
  @carrier = "carrier_broker_dealer"
  @business_name = "BO upper tier " + organisation_type.to_s
  @copy_cards = rand(3)

  start_reg_from_back_office
  step("I complete my registration for my business '#{@business_name}'")

end

Given("I register an lower tier {string} from the back office") do |organisation_type|
  @organisation_type = organisation_type
  @app = "bo"
  @reg_type = :new_registration
  @tier = "lower"
  @business_name = "BO lower tier " + organisation_type.to_s

  start_reg_from_back_office
  step("I complete my registration for my business '#{@business_name}'")

end

When("I cancel the registration") do
  visit_registration_details_page(@reg_number)

  @bo.registration_details_page.cancel_link.click
  @journey.standard_page.submit
end

When("I am about to cancel the registration and change my mind") do
  visit_registration_details_page(@reg_number)

  @bo.registration_details_page.cancel_link.click
  click_link("Keep this registration")
end
