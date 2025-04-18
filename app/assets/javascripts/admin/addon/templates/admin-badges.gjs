import { LinkTo } from "@ember/routing";
import RouteTemplate from "ember-route-template";
import BadgeButton from "discourse/components/badge-button";
import DBreadcrumbsItem from "discourse/components/d-breadcrumbs-item";
import DPageHeader from "discourse/components/d-page-header";
import routeAction from "discourse/helpers/route-action";
import { i18n } from "discourse-i18n";

export default RouteTemplate(
  <template>
    <div class="badges">
      <DPageHeader
        @titleLabel={{i18n "admin.config.badges.title"}}
        @descriptionLabel={{i18n "admin.config.badges.header_description"}}
        @learnMoreUrl="https://meta.discourse.org/t/understanding-and-using-badges/32540"
      >
        <:breadcrumbs>
          <DBreadcrumbsItem @path="/admin" @label={{i18n "admin_title"}} />
          <DBreadcrumbsItem
            @path="/admin/badges"
            @label={{i18n "admin.config.badges.title"}}
          />
        </:breadcrumbs>
        <:actions as |actions|>
          <actions.Primary
            @route="adminBadges.show"
            @routeModels="new"
            @icon="plus"
            @label="admin.badges.new"
            class="new-badge"
          />

          <actions.Default
            @route="adminBadges.award"
            @routeModels="new"
            @icon="upload"
            @label="admin.badges.mass_award.title"
            class="award-badge"
          />

          <actions.Default
            @action={{routeAction "editGroupings"}}
            @title="admin.badges.group_settings"
            @label="admin.badges.group_settings"
            @icon="gear"
            class="edit-groupings-btn"
          />
        </:actions>
      </DPageHeader>

      <div class="admin-container">
        <div class="content-list">
          <ul class="admin-badge-list">
            {{#each @controller.model as |badge|}}
              <li class="admin-badge-list-item">
                <LinkTo
                  @route={{@controller.selectedRoute}}
                  @model={{badge.id}}
                >
                  <BadgeButton @badge={{badge}} />
                  {{#if badge.newBadge}}
                    <span class="list-badge">{{i18n
                        "filters.new.lower_title"
                      }}</span>
                  {{/if}}
                </LinkTo>
              </li>
            {{/each}}
          </ul>
        </div>
        {{outlet}}
      </div>
    </div>
  </template>
);
