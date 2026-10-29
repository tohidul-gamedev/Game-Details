# Asset permission ও archived asset — আলাদা অনুসন্ধান রিপোর্ট

আপনার নতুন Studio Output screenshot-এর ১০টি আলাদা ID, আগের দেওয়া `Bangladeshi Tower 41.rbxl`-এর parsed properties এবং সব উদ্ধার করা script Source-এর সঙ্গে মিলিয়ে দেখা হয়েছে। ৯টি ID পাওয়া গেছে: **২৫টি object-property reference এবং ১২টি script-source reference, মোট ৩৭টি**। Script-এর একই লাইনে একই ID একাধিকবার থাকলে occurrence গণনা আলাদা হতে পারে; এখানে এই snapshot-এর মিলগুলো দেওয়া হয়েছে।

ফাইলের SHA-256: `a7db9ec7969bf578ba8dbff2eef1eee694735e44a3cc9d6d423197fe38757a89`। এটি আপনার বর্তমান Studio version-এর snapshot কি না নিশ্চিত নয়। কোনো property, code বা permission পরিবর্তন করা হয়নি। Online asset permission বা owner account যাচাই করা হয়নি; error-এর ধরন screenshot থেকে নেওয়া। এটি file-reference অনুসন্ধান, live web গবেষণার দাবি নয়।

## ১. Permission denied — গানের চারটি deeply nested Sound

সবগুলোর property **SoundId**। Workspace-এর `banglaMusic`-এর ভিতরে Sound-এর child হিসেবেও আরও Sound আছে; তাই শুধু top-level folder খুলে খুঁজলে এগুলো চোখে নাও পড়তে পারে। নামের punctuation, space এবং `MOMBATI `-এর শেষে space আছে; নাম দেখে dot-separated Lua expression বানাবেন না। Exact breadcrumb তালিকা `All-References.html`-এ এবং scanner-এ selection সুবিধা আছে।

| ID | Object-এর Name | মূল অবস্থান |
|---|---|---|
| 137554909322431 | `MOMBATI ` (শেষে space) | Workspace.banglaMusic |
| 75160593025484 | `O Tunir Ma Tomar Tuni` | একই nested music subtree |
| 136769849825926 | `Jaane Kyun - Tanveer Evan Cover by Lizaz` | একই nested music subtree |
| 133285462741466 | `sad song1` | একই nested music subtree |

এগুলোতে screenshot বলছে `Asset is not approved for the requester`। নিজস্ব/অনুমোদিত বিকল্প audio ID বসান বা owner-এর মাধ্যমে ওই experience-কে asset ব্যবহারের access দিন। শুধু গানের নাম বদলালে কাজ হবে না। দরকার না হলে reference সরানোর আগে parent Sound-এর child-গুলোর কী হবে যাচাই করুন—parent মুছলে nested অন্য গানও মুছে যাবে।

## ২. Permission denied — Shesh Kanna: ৮টি reference

ID **119728152122091**:

SoundId:

- `Workspace.MusicZone.Songs.Shesh Kanna`
- `ReplicatedStorage.Musics.Shesh Kanna`

Source playlist entries:

| Exact script path | Line |
|---|---:|
| ReplicatedStorage.Tools.Tools.BoomBox.Client | 35 |
| ReplicatedStorage.Tools.Tools.BoomBox 2.Client | 19 |
| ReplicatedStorage.Tools.Tools.BoomBox 3.Client | 31 |
| ReplicatedStorage.Tools.BoomBox.Client | 30 |
| ServerStorage.Folder.Tools.BoomBox.Client | 30 |
| ServerStorage.Tools.BoomBox.Client | 71 |

**একটি Sound ঠিক করলেই শেষ নয়।** একই ID script playlist-এর ৬টি জায়গাতেও বদলাতে/সরাতে হবে; নইলে tool clone/equip হলে পুরোনো ID আবার ব্যবহার হতে পারে। User-saved favourites-এ পুরোনো ID থাকতে পারে—সেটি static file-এ নেই; প্রয়োজনে পুরোনো ID-কে unavailable হিসেবে gracefully handle করুন, সব user data মুছবেন না।

## ৩. Permission denied — Chiro Odhora: ৮টি reference

ID **114284944645440**:

SoundId:

- `Workspace.MusicZone.Songs.Chiro Odhora`
- `ReplicatedStorage.Musics.Chiro Odhora`

Source playlist entries:

| Exact script path | Line |
|---|---:|
| ReplicatedStorage.Tools.Tools.BoomBox.Client | 42 |
| ReplicatedStorage.Tools.Tools.BoomBox 2.Client | 26 |
| ReplicatedStorage.Tools.Tools.BoomBox 3.Client | 38 |
| ReplicatedStorage.Tools.BoomBox.Client | 37 |
| ServerStorage.Folder.Tools.BoomBox.Client | 37 |
| ServerStorage.Tools.BoomBox.Client | 78 |

পূর্বের মতো object ও playlist—দুই ধরনের reference-ই সংশোধন করা দরকার। Disabled/stored copy-ও ভবিষ্যতে clone হলে আবার error আনতে পারে। বর্তমান snapshot-এ একেবারে নিষ্ক্রিয় copy মানেই এটিই error trigger করেছে—এমন নয়।

## ৪. Permission denied — Hammer effect-এর sound

ID **8578316223**:

`ReplicatedStorage.VFX.Templates.UltraHammerGiant.DiamondHammer.Handle.MainChargeSound`

Class **Sound**, property **SoundId**। এটি effect template-এর ভেতরের sound। তাই music playlist-এ খুঁজলে পাওয়া যাবে না। অনুমোদিত charging sound দিয়ে property বদলান, অথবা effect code সামঞ্জস্য রেখে sound ব্যবহার বন্ধ করুন। Object সরিয়ে দিলে `WaitForChild` ভাঙবে কি না যাচাই করুন।

## ৫. Archived — bathroom teleport sound

ID **137448731583582**:

`ServerStorage.Other Trass of server storage.bathroom Main Model.tppart.Sound`

Class **Sound**, property **SoundId**। Screenshot-এর error **Requested asset is archived**। এটি permission error-এর সঙ্গে এক নয়; শুধু experience permission দেওয়াই archived asset-এর সমাধান নয়। Owner-এর উপযুক্ত restore/unarchive ব্যবস্থা থাকলে সেটি ব্যবহার, অন্যথায় কার্যকর অনুমোদিত asset দিয়ে replacement দরকার।

এটি stored model-এর ভেতরে আছে। Template inspect/preload বা runtime clone-এ load হতে পারে; এই exact instance-ই screenshot মুহূর্তে trigger করেছে কি না file-only analysis প্রমাণ করে না।

## ৬. Permission denied — fishing effect texture: ১৫টি property

ID **14795103410** কোনো গান নয়: এটি **ParticleEmitter.Texture**। Object-এর Name `Specs`।

| Subtree | Reference সংখ্যা |
|---|---:|
| Workspace.FishingNPCS.FishingShopC1.Items.Items | 5 |
| ReplicatedStorage.FishingRodSystem.FishTemplates.Mammoth Fish | 2 |
| ReplicatedStorage.FishingRodSystem.FishingRods.Divine Rod | 1 |
| ReplicatedStorage.FishingRodSystem.FishingRods.Diamond Rod | 4 |
| ReplicatedStorage.FishingRodSystem.FishingRods.Angelic Rod | 2 |
| ReplicatedStorage.FishingRodSystem.FishingRods.Flower Rod | 1 |

সম্পূর্ণ ১৫টি exact path এবং breadcrumb `All-References.html` ও CSV-তে আছে। কিছু sibling-এর একই Name/একই GetFullName আছে; এরা আলাদা instance। Parser ID শুধু এই extraction-এর reference, Roblox Asset ID নয়। Studio helper সব matching instance select করে; তাই একই নামের duplicate বাদ পড়বে না।

**সমাধান:** ব্যবহারযোগ্য particle image/texture দিয়ে **১৫টি Texture property** update করুন। NPC display copy, fish template ও rod template সব রাখুন। শুধু ParticleEmitter.Enabled false করলে texture reference মুছে যায় না; editor/preloader সেটি load করার চেষ্টা করতে পারে। অপ্রয়োজনীয় emitter/reference সরাতে dependencies যাচাই করুন।

## ৭. Archived plugin icon — 1014915761

স্ক্রিনশটে একই ID-র জন্য `Requested asset is archived` এবং **Unable to load plugin icon** আছে। Parsed place properties ও script-এর literal numeric reference-এ ID পাওয়া যায়নি। Donation decoded-string snapshot-এও match আছে কি না যাচাইয়ের ফল Evidence.json-এ দেওয়া হয়েছে।

এটি Studio-তে installed কোনো plugin-এর icon-এর error হওয়ার শক্ত প্রমাণ। কাছে MultiPhotobooth/Eclipse-এর log আছে বলে ওই plugin-ই দায়ী, বলা যায় না। `.rbxl`-এ local installed plugin-এর source সাধারণত থাকে না।

**সমাধান:** Studio-র Plugins/Manage Plugins থেকে সন্দেহভাজন plugin একবারে একটি disable করে Studio restart ও Output পরীক্ষা করুন। চিহ্নিত হলে plugin update/reinstall বা creator-কে broken icon জানান। গেমের object অন্ধভাবে মুছবেন না। Literal reference না পাওয়া encoded বা externally loaded reference একেবারে নেই—এমন প্রমাণ নয়।

## নিজে Studio-তে exact object নির্বাচন করবেন যেভাবে

১. একই game-এর backup রেখে **Play বন্ধ করে Edit mode-এ** কাজ করুন।

২. `Find-Asset-References-Studio.lua` খুলে Studio Command Bar-এ paste/run করুন। এটি SoundId, ParticleEmitter.Texture ও script Source-এর screenshot IDs খোঁজে; matching objects select করে এবং Output-এ path/property/source line লেখে। শুধু editor selection বদলায়, game data নয়। কোনো Source পড়ার permission না থাকলে warning দেয়।

৩. Helper Roblox Studio-তে এখানে চালানো হয়নি; তাই current project-এ runtime verified দাবি নয়। Uploaded snapshot-এর জন্য expected মোট matches ৩৭, unique selected instances ৩১। আপনার current version আলাদা হলে সংখ্যা বদলাতে পারে। Plugin icon game descendants scan-এ না-ও আসবে।

৪. Script Source-এর ID খুঁজতে Studio Find All Scripts-এ ID লিখুন। এতে SoundId/Texture property খোঁজা হয় না—তাই source-only search-এ সব ২৫টি property পাওয়া যায়নি বলে অবাক হওয়ার দরকার নেই।

৫. অনুমোদিত replacement দিয়ে সংশ্লিষ্ট সব template ও playlist update করে Output clear → playtest → affected tool/effect/rod/music ব্যবহার → live experience test করুন। Save/publish স্বয়ংক্রিয়ভাবে asset access দেয় না; experience-এর ownership/access scope মিলতে হবে।

## Lag/crash-এর সঙ্গে সম্পর্ক

এই errors মূলত audio বা particle texture load ব্যর্থতা বোঝায়। বারবার retry/preload/log spam হলে বাড়তি কাজ হতে পারে, কিন্তু এগুলোকে ৫০ KB/s Receive বা historical server process crash-এর নিশ্চিত কারণ বলা যায় না। Permission/archived সমস্যা আলাদা ঠিক করে তারপর একই baseline-এ performance যাচাই করুন।

## সীমা

শুধু screenshot-এর এই ১০টি ID-এর mapping। সব asset-এর online permission যাচাই নয়। Parser source/property search, packed Donation payload-এর ইতিমধ্যে decoded strings ও raw bytes-এর literal search—encoded/computed/externally loaded ID-এর পূর্ণ অনুসন্ধান নয়। Runtime clone-এর ancestor আলাদা হবে; source template path এখানে দেখানো। Screenshot নতুন Studio version-এর হলে path/line বদলে থাকতে পারে। মূল `.rbxl` অক্ষত আছে।
