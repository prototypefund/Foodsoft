# frozen_string_literal: true

require 'spec_helper'

describe HomeController, type: :controller do
  let(:user) { create :user }

  describe 'GET index' do
    describe 'NOT logged in' do
      it 'redirects' do
        get :profile, params: { foodcoop: FoodsoftConfig[:default_scope] }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(login_path)
      end
    end

    describe 'logegd in' do
      before { login user }

      it 'assigns tasks' do
        get :index, params: { foodcoop: FoodsoftConfig[:default_scope] }

        expect(assigns(:unaccepted_tasks)).not_to be_nil
        expect(assigns(:next_tasks)).not_to be_nil
        expect(assigns(:unassigned_tasks)).not_to be_nil
        expect(response).to render_template('home/index')
      end
    end
  end

  describe 'GET profile' do
    before { login user }

    it 'renders dashboard' do
      get :profile, params: { foodcoop: FoodsoftConfig[:default_scope] }
      expect(response).to have_http_status(:success)
      expect(response).to render_template('home/profile')
    end
  end

  describe 'GET reference_calculator' do
    describe 'with simple user' do
      before { login user }

      it 'redirects to home' do
        get :reference_calculator, params: { foodcoop: FoodsoftConfig[:default_scope] }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'with ordergroup user' do
      let(:og_user) { create :user, :ordergroup }

      before { login og_user }

      it 'renders reference calculator' do
        get :reference_calculator, params: { foodcoop: FoodsoftConfig[:default_scope] }
        expect(response).to have_http_status(:success)
        expect(response).to render_template('home/reference_calculator')
      end
    end
  end

  describe 'GET update_profile' do
    describe 'with simple user' do
      let(:unchanged_attributes) { user.attributes.slice('first_name', 'last_name', 'email') }
      let(:changed_attributes) { attributes_for :user }
      let(:invalid_attributes) { { email: 'e.mail.com' } }

      before { login user }

      it 'renders profile after update with invalid attributes' do
        get :update_profile, params: { foodcoop: FoodsoftConfig[:default_scope], user: invalid_attributes }
        expect(response).to have_http_status(:success)
        expect(response).to render_template('home/profile')
        expect(assigns(:current_user).errors.present?).to be true
      end

      it 'redirects to profile after update with unchanged attributes' do
        get :update_profile, params: { foodcoop: FoodsoftConfig[:default_scope], user: unchanged_attributes }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(my_profile_path)
      end

      it 'redirects to profile after update' do
        patch :update_profile, params: { foodcoop: FoodsoftConfig[:default_scope], user: changed_attributes }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(my_profile_path)
        expect(flash[:notice]).to match(/#{I18n.t('home.changes_saved')}/)
        expect(user.reload.attributes.slice(:first_name, :last_name, :email)).to eq(changed_attributes.slice('first_name', 'last_name', 'email'))
      end
    end

    describe 'with ordergroup user' do
      let(:og_user) { create :user, :ordergroup }
      let(:unchanged_attributes) { og_user.attributes.slice('first_name', 'last_name', 'email') }
      let(:changed_attributes) { unchanged_attributes.merge({ ordergroup: { contact_address: 'new Adress 7' } }) }

      before { login og_user }

      it 'redirects to home after update' do
        get :update_profile, params: { foodcoop: FoodsoftConfig[:default_scope], user: changed_attributes }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(my_profile_path)
        expect(og_user.reload.ordergroup.contact_address).to eq('new Adress 7')
      end
    end
  end

  describe 'GET ordergroup' do
    describe 'with simple user' do
      before { login user }

      it 'redirects to home' do
        get :ordergroup, params: { foodcoop: FoodsoftConfig[:default_scope] }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'with ordergroup user' do
      let(:og_user) { create :user, :ordergroup }

      before { login og_user }

      it 'renders ordergroup' do
        get :ordergroup, params: { foodcoop: FoodsoftConfig[:default_scope] }
        expect(response).to have_http_status(:success)
        expect(response).to render_template('home/ordergroup')
      end

      describe 'assigns sortings' do
        let(:fin_trans1) { create :financial_transaction, user: og_user, ordergroup: og_user.ordergroup, note: 'A', amount: 100 }
        let(:fin_trans2) { create :financial_transaction, user: og_user, ordergroup: og_user.ordergroup, note: 'B', amount: 200, created_on: Time.now + 1.minute }

        before do
          fin_trans1
          fin_trans2
        end

        it 'by criteria' do
          sortings = [
            ['date', [fin_trans1, fin_trans2]],
            ['note', [fin_trans1, fin_trans2]],
            ['amount', [fin_trans1, fin_trans2]],
            ['date_reverse', [fin_trans2, fin_trans1]],
            ['note_reverse', [fin_trans2, fin_trans1]],
            ['amount_reverse', [fin_trans2, fin_trans1]]
          ]
          sortings.each do |sorting|
            get :ordergroup, params: { foodcoop: FoodsoftConfig[:default_scope], sort: sorting[0] }
            expect(response).to have_http_status(:success)

            expect(assigns(:financial_transactions).to_a).to eq(sorting[1])
          end
        end
      end
    end
  end

  describe 'GET cancel_membership' do
    describe 'with simple user without group' do
      before { login user }

      it 'fails' do
        expect do
          get :cancel_membership, params: { foodcoop: FoodsoftConfig[:default_scope] }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'with ordergroup user' do
      let(:fin_user) { create :user, :role_finance }

      before { login fin_user }

      it 'removes user from group' do
        membership = fin_user.memberships.first
        get :cancel_membership,
            params: { foodcoop: FoodsoftConfig[:default_scope],
                      group_id: fin_user.groups.first.id }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(my_profile_path)
        expect(flash[:notice]).to match(/#{I18n.t('home.ordergroup_cancelled', :group => membership.group.name)}/)
      end
    end
  end
end