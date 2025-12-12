# Account Engagement Web Form Playbook

Practical, field-ready steps to build seven production-ready Pardot (Account Engagement) web forms that sync cleanly to Salesforce and capture UTM/behavioral data.

## Stage 1: Salesforce + Pardot Field Infrastructure
- Confirm required fields exist on both Lead and Contact; verify Visibility/Edit for the B2BMA/Pardot Integration User: `pi__utm_source__c`, `pi__utm_medium__c`, `pi__utm_campaign__c`, `pi__utm_term__c`, `pi__utm_content__c`, `pi__score__c`, `pi__grade__c`, `pi__last_activity__c`, `pi__pardot_hard_bounced__c`, `pi__Pardot_Last_Scored_At__c`, `pi__first_touch_url__c`, `pi__first_activity__c`, `pi__first_search_term__c`, `pi__first_search_type__c`, `pi__conversion_object_name__c`, `pi__conversion_object_type__c`, `pi__url__c`, `pi__comments__c`, `pi__notes__c`, `pi__created_date__c`.
- In Salesforce: Setup → Object Manager → Lead/Contact → Fields & Relationships; ensure field-level security is exposed to the integration user and page layouts as needed.
- In Pardot: Admin → Configure Fields → Prospect Fields; map to the above Salesforce fields and set sync behavior (e.g., Pardot wins for UTMs, Salesforce wins for core identity fields).

## Stage 2: Tracker Domain
- Choose branded subdomain (e.g., `go.yourcompany.com`); create DNS CNAME `go.yourcompany.com` → `go.pardot.com`.
- Pardot: Settings → Domain Management → add, validate, set as Primary Tracker Domain. Ensure SSL is active.

## Stage 3: Salesforce Campaigns
- Create one Campaign per form: Name `Web Form – [Form Name]`, Status `Active`, Type `Web`; optionally parent to `Website Forms 2025`.

## Stage 4: Build Forms in Pardot (repeat x7)
- Pardot → Content → Forms → Add Form; select Folder and corresponding Campaign.
- Visible/required fields: First Name, Last Name, Email, Company, Phone (opt), Comments (`pi__comments__c`), Industry/Job Title as needed.
- Hidden fields (UTM/tracking): `pi__utm_source__c`, `pi__utm_medium__c`, `pi__utm_campaign__c`, `pi__utm_term__c`, `pi__utm_content__c`, `pi__first_touch_url__c` (optional if auto).
- Optional hidden: `pi__conversion_object_type__c`, `pi__conversion_object_name__c`.
- Completion Actions: Add to Salesforce Campaign (Status `Responded`), Assign to User/Queue, Notify User, adjust Score/Grade if desired.
- Look & Feel: disable default styling if using site CSS; set thank-you content/redirect URL; enable bot protection (reCAPTCHA v3) if available.

## Stage 5: Tracking Script
- Add globally to site pages (especially form pages):
```html
<script type="text/javascript" src="https://pi.pardot.com/pd.js"></script>
```
- Confirms cookie tracking and populates Pardot `pi__*` fields (first touch URL, last activity, conversion object metadata).

## Stage 6: Optional UTM Auto-Capture
- If you need to prefill hidden fields from URL params, add to site header (adjust selectors to match your form embed):
```html
<script>
  function getUrlParam(param) {
    var m = new RegExp('[?&]' + param + '=([^&#]*)').exec(window.location.href);
    return m ? decodeURIComponent(m[1].replace(/\+/g, ' ')) : '';
  }
  window.addEventListener('load', function () {
    ['utm_source','utm_medium','utm_campaign','utm_term','utm_content'].forEach(function(key){
      var el = document.querySelector('input[name="' + key + '"]');
      if (el && !el.value) el.value = getUrlParam(key);
    });
  });
 </script>
```
- Ensure hidden input `name` attributes match Pardot field aliases used in the form.

## Stage 7: Embed Forms
- After form creation: Form → View HTML Code → choose iframe or JavaScript embed; place on the target page.
- Confirm embed URL uses your tracker domain (e.g., `https://go.yourcompany.com/l/12345/2025-12-10/abc123`).

## Stage 8: Validate & Test (per form)
- Submit test with UTM params (e.g., `...?utm_source=linkedin&utm_medium=paid&utm_campaign=product-launch`).
- Verify: Prospect created in Pardot; visible + hidden fields populated; `pi__` fields present; sync to Salesforce Lead/Contact; Campaign association correct; auto-assignment/notifications fire.
- Retest after cache/CDN deploys; test in incognito to validate cookie creation.

## Bonus: Reporting & Automation
- Use Pardot Automation Rules for grading, assignment, and alerts per form/campaign.
- Surface data via B2BMA dashboards or Salesforce Campaign/Engagement History reports.
- Add the Engagement History Lightning component to Lead/Contact to expose UTM + campaign details to reps.
