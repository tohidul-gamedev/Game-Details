# Bangladeshi Tower — Game Audit Reports

`Bangladeshi Tower 41.rbxl` ও দেওয়া screenshots-এর ভিত্তিতে বাংলা static audit। রিপোর্টের তারিখ: **২৯ অক্টোবর ২০২৬**।

## রিপোর্ট পড়ুন

1. [Receive, replication ও client lag রিপোর্ট](reports/2026-10-29/performance/01-Receive-Report-BN.md)
2. [Server crash, memory growth ও shutdown রিপোর্ট](reports/2026-10-29/performance/02-Server-Crash-Report-BN.md)
3. [সব ১,৪১০টি script-এর inventory — CSV](reports/2026-10-29/performance/03-Script-Inventory.csv)
4. [Asset permission / archived asset অনুসন্ধান ও সমাধান](reports/2026-10-29/asset-permissions/README-BN.md)
5. [Asset-এর সব ৩৭টি reference — CSV](reports/2026-10-29/asset-permissions/All-References.csv)
6. [Studio-তে matching object select করার read-only helper](reports/2026-10-29/asset-permissions/Find-Asset-References-Studio.lua)

## HTML ও সম্পূর্ণ প্যাকেজ ডাউনলোড

- [Receive + crash + searchable script inventory ZIP](downloads/Bangladeshi-Tower-Audit-BN.zip)
- [Asset permission report + exact paths + Studio helper ZIP](downloads/Asset-Permission-Audit-BN.zip)

ZIP download করে extract করার পরে `.html` ফাইল browser-এ খুলুন। Searchable inventory এবং সম্পূর্ণ Explorer breadcrumb এতে দেখা যায়। GitHub-এর সাধারণ file view HTML report-কে webpage হিসেবে চালায় না।

HTML copies repository-তেও আছে: [Receive](reports/2026-10-29/performance/01-Receive-Report-BN.html), [Crash](reports/2026-10-29/performance/02-Server-Crash-Report-BN.html), [Script inventory](reports/2026-10-29/performance/03-Script-Inventory.html), [Asset report](reports/2026-10-29/asset-permissions/README-BN.html), [Exact asset locations](reports/2026-10-29/asset-permissions/All-References.html)।

## পরিধি ও সীমাবদ্ধতা

- ৭৯,৪৫৯টি instance ও ১,৪১০টি script source উদ্ধার; ৬৯৫টি পৃথক source। সব source pattern scan এবং গুরুত্বপূর্ণ readable server/network/lifecycle code-এর targeted review হয়েছে। সব code path manually বা runtime পরীক্ষা হয়নি।
- Screenshot-এর ১০টি asset ID-এর মধ্যে ৯টির ৩৭টি reference পাওয়া গেছে; একটি plugin-icon error আলাদাভাবে চিহ্নিত।
- Roblox Studio/live server চালিয়ে crash reproduce বা exact bandwidth attribution করা হয়নি। Obfuscated/externally loaded code-এর সীমাবদ্ধতা রিপোর্টে আছে।
- Finding মানেই historical crash-এর নিশ্চিত কারণ নয়। প্রতিটি রিপোর্টে evidence, proposed fix ও verification plan আলাদা আছে।
- এই repository update-এ report ও diagnostic helper দেওয়া হয়েছে; game place/source পরিবর্তন বা game publish করা হয়নি।

[Performance audit manifest](reports/2026-10-29/performance/Audit-Manifest.json) · [Asset matching evidence](reports/2026-10-29/asset-permissions/Evidence.json)
