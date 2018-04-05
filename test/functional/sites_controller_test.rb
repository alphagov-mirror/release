require "test_helper"

class SitesControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  context "GET show" do
    should "redirect when the user has no deploy permissions" do
      actions_requiring_deploy_permission_redirect(:get, :show)
    end

    should 'render the show template with an empty form if no site settings are persisted' do
      get :show
      assert_template :show

      assert_select 'form.site[action="/site"]'
      assert_select 'form.site textarea[name="site[status_notes]"]', ''
    end

    should 'render the show template with a form filled with the existing site settings' do
      FactoryBot.create(:site, status_notes: 'Deploy freeze in place.')
      get :show
      assert_template :show

      assert_select 'form.site[action="/site"]'
      assert_select 'form.site textarea[name="site[status_notes]"]', 'Deploy freeze in place.'
    end
  end

  context "PATCH update" do
    should "redirect when the user has no deploy permissions" do
      actions_requiring_deploy_permission_redirect(:patch, :update, site: { status_notes: 'No deploys plz!' })
    end

    should "create some site settings if there are none" do
      refute Site.settings.persisted?

      patch :update, params: { site: { status_notes: 'Deploy freeze in place.' } }

      assert Site.settings.persisted?
      assert_equal 'Deploy freeze in place.', Site.settings.status_notes
    end

    should "update the exiting site settings if they exist" do
      site_settings = FactoryBot.create(:site, status_notes: 'Deploys are frozen for now.')

      patch :update, params: { site: { status_notes: 'Deploy freeze in place.' } }

      assert_equal 'Deploy freeze in place.', site_settings.reload.status_notes
    end

    should "rerender the form if the site settings won't save" do
      patch :update, params: { site: { status_notes: 'a' * 256 } }

      refute Site.settings.persisted?

      assert_select 'form.site[action="/site"]'
      assert_select 'form.site textarea[name="site[status_notes]"]', 'a' * 256
    end
  end
end