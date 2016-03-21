#!/usr/bin/env ruby
Bundler.require

url = "http://planning.nambucca.nsw.gov.au/PlanningServices/ATDISService.svc/"

ATDISPlanningAlertsFeed.save(url)