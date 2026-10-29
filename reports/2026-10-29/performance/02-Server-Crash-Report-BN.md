# রিপোর্ট ২ — Server crash / memory growth / shutdown

পরীক্ষিত ফাইল: **Bangladeshi Tower 41.rbxl**, ২৯ অক্টোবর ২০২৬।

## মূল সিদ্ধান্ত

**এই ফাইল থেকে historical server crash-এর একটিমাত্র নিশ্চিত দায়ী script নির্ধারণ করা যায়নি।** Crash stack/dump, server-age অনুযায়ী memory graph এবং incident-এর last logs ছাড়া “এই script-ই ১২ GB করেছে” বলা প্রমাণহীন। তবে নির্দিষ্ট input-validation দুর্বলতা, resource-lifecycle ঝুঁকি, server GUI work ও বড় static world পাওয়া গেছে—এগুলো সংশোধনের যথেষ্ট কারণ আছে।

আপনার server তালিকায় ৯টি crash: ৬টির দৃশ্যমান memory ৮৮৮–১,২৬২ MB; বাকি ৫,২৭২ / ১১,১২৯ / ১২,২৯১ MB। অতএব সব crash কেবল high-memory-এর নয়। তালিকার শেষ sampled memory/frame rate ক্র্যাশের ঠিক আগের সম্পূর্ণ অবস্থা নাও হতে পারে; হঠাৎ spike বাদ যায় না। ১২,২৯১ MB সার্ভারে ৪৫ player ও ৪৮ FPS ছিল—এটি চাপের প্রমাণ, cause-এর প্রমাণ নয়।

সব source উদ্ধার/pattern scan করা হয়েছে; high-risk readable server code বিস্তারিত পড়া হয়েছে। Packed/obfuscated script, externally required module এবং runtime-loaded asset-এর আচরণ পুরো যাচাই করা যায়নি। Roblox Studio/live server এখানে চালানো হয়নি, কোনো crash reproduce করা হয়নি। ফাইলের সংস্করণ তালিকার v3771/v4191-এর কোনটির সঙ্গে মিলে তা নিশ্চিত নয়।

## C1 — ArmServer: arbitrary instance দিয়ে persistent Match entry তৈরি হয়

**অগ্রাধিকার: উচ্চ। Code defect নিশ্চিত; historical crash attribution অপ্রমাণিত।**

Path: `ServerScriptService.ArmServer.ArmServer`; source `54092_ArmServer.lua`।

- line 258–264: `JoinMatch` শুধু `typeof(tableModel) == "Instance"` দেখে; নির্দিষ্ট table folder, Model type, required children, distance বা player already-in-match পরীক্ষা করে না।
- line 262: validation সম্পূর্ণ করার আগেই `Matches[tableModel] = Match.new(tableModel)` হয়।
- line 82–90: Player reference set করার পরে missing Pad/Table child access error হতে পারে। তখন তৈরি entry সরানো হয় না।
- পুরো script-এ Matches entry purge নেই; PlayerRemoving match শেষ করে, কিন্তু registry key সরায় না। বৈধ স্থির tables-এর জন্য cache সীমিত হতে পারে; arbitrary instance গ্রহণে সেই সীমা নেই।
- line 222–249: client multiplier-এর finite/bounds validation ও click rate cap নেই। NaN/অস্বাভাবিক value game state নষ্ট করতে পারে।

**সমাধান:** startup-এ legitimate tables-এর registry বানান; incoming table সেটির member কি না, workspace-এ আছে কি না, distance/character/player state valid কি না—allocation-এর আগে দেখুন। এক player এক match। Table destroy-এ registry ও tracks/tasks cleanup; match cancellation token। Server-owned bounded power এবং click budget দিন।

**যাচাই:** private Studio test-এ invalid input-এ Match count অপরিবর্তিত থাকবে, valid table count ছাড়াবে না। বহু join/leave/respawn-এর পরে player reference থাকবে না। Live flood test করার দরকার নেই।

## C2 — ArmServer: animation load অপেক্ষার timeout নেই

একই source line 184 ও 195-এ `repeat task.wait(0.05) until track.Length > 0`। Asset load ব্যর্থ বা track তাড়াতাড়ি destroy হলে worker শেষ নাও হতে পারে। Game চলতে থাকলে এমন অপেক্ষমাণ worker বাড়ার সম্ভাবনা আছে।

**সমাধান:** bounded timeout, character/track existence check ও match token; timeout/cancel-এ worker শেষ করুন। `End`/leave/respawn-এ অপেক্ষমাণ tasks-ও বাতিল করুন। Actual retained-memory impact profiling দরকার।

## C3 — AdminServer: sleeping Heartbeat callbacks ও character lifecycle

Path: `ServerScriptService.Admin Panel.AdminServer`; source `53994_AdminServer.lua`।

line 642-এর LoopReset callback প্রতি Heartbeat-এ শুরু হয়ে ভিতরে configured interval অপেক্ষা করে। নতুন invocation ততক্ষণ থামে না। Fixed interval থাকলে backlog সাধারণত interval×frame rate-এর কাছাকাছি bounded হতে পারে; একে স্বয়ংক্রিয় অনন্ত leak বলা হচ্ছে না। তবু অপ্রয়োজনীয় suspended work ও reset pressure তৈরি করে।

Spin/Drunk/Disco loop পুরোনো character capture করে; respawn-এ পুরোনো loop পরিষ্কার/rebind করার স্পষ্ট path নেই। PlayerRemoving-এ connection cleanup আছে। Fire loop-এ (line 192 থেকে) damage না হলে totalDamage বাড়ে না; character নেই/মরে গেছে এবং effect flag true থাকলে loop দীর্ঘস্থায়ী হতে পারে। শুধু activeEffects-এর table key মুছে দিলে captured পুরোনো effects table-এর flag নিজে false হয় না।

**সমাধান:** একটি owner-managed task প্রতি effect; explicit cancel flag/token; CharacterRemoving, death, toggle-off ও PlayerRemoving-এ cancel। Pure cosmetic রং client-এ। Admin commands rate-limit এবং spawned tool/effect cap।

**যাচাই:** effect start → death → respawn → stop → leave চক্র বহুবার; pending task/connection ও retained character memory baseline-এ ফেরে কি না মাপুন। Effect চালু না থাকলে এটি idle server crash ব্যাখ্যা নয়।

## C4 — AnimationTrack ownership: RPS ও sitting scripts

- `ServerScriptService.RPS_Server.RPS_Server`, `54095_RPS_Server.lua` line 222–235: নতুন Animation/track load; line 447–448 প্রতি round-এ দুই player-এ call, দ্বিতীয় track সংরক্ষণ করা হয় না। Match/round cleanup-এ ওই tracks-এর explicit Stop/Destroy নেই। Non-looping track শেষ হওয়া মানেই স্থায়ী leak নিশ্চিত নয়; ownership ও cleanup অসম্পূর্ণ।
- `Workspace.All Stage Bance`-এ ৬৬টি enabled seat animation script আছে; এক seat-এ তিনটি script নয়—৩টি source variant-এর প্রতিটির ২২টি copy, মোট ৬৬টি পৃথক seat। উদাহরণ `23405_Sit_animation_paly.lua` line 20–30: প্রতিবার নতুন Animation/track, উঠে গেলে শুধু Stop ও reference nil।
- Bike `28018_IKControl.lua` line 11–15: currentAnim Stop ও nil; IK instance cleanup আছে। Track Destroy-ও যোগ করা উচিত।

**সমাধান:** animation source reusable/cache; প্রতি character/seat-এর track lifecycle নির্দিষ্ট করুন। Finished/cancelled track ও temporary Animation Destroy; leave/death/match abort ও streaming/dynamic deletion path test। অসংখ্য track তৈরি না করে সীমিত reusable track ব্যবহার।

এগুলো risk-reduction finding; এগুলো একাই ১২ GB হয়েছে—এমন measurement নেই।

## C5 — Boxing helper cache: server visitor count-এর সঙ্গে বাড়তে পারে

`ReplicatedStorage.BoxingSystem.Modules.SessionTracker`, `51922_SessionTracker.lua`: line 16–18 userId অনুযায়ী sessionData entry; PlayerRemoving/TTL/size cap নেই। Response top-10 হলেও backing table সব visitor রাখে।

`InviteHandler`, `51919_InviteHandler.lua`: line 21–30 nested PendingInvites table; accept/decline কিছু entry মুছে, কিন্তু expired invite ও departed-user cleanup নেই।

**সমাধান:** active players-এর তথ্য চাইলে leave-এ purge; departed player-এর session record feature দরকার হলে bounded TTL/LRU বা স্পষ্ট maximum। Invite expire/cancel/leave-এ দুই দিকের entry clear।

**সীমা:** এগুলো ModuleScript। বর্তমান obfuscated BoxingServer কোনভাবে initialize করে তা সম্পূর্ণ যাচাই হয়নি। তাই module activation সাপেক্ষ finding। ছোট numeric/string cache দেখে ১২ GB-এর প্রধান কারণ দাবি নয়।

## C6 — FishDataStore: ownership validation এবং inventory limits

Path: `ReplicatedStorage.FishingRodSystem.Modules.FishDataStore`; source `45590_FishDataStore.lua`।

line 106 থেকে `UnequipVirtualFish` passed Instance-কে Tool কি না দেখে, কিন্তু request করা player's Backpack/Character-এর নিজস্ব eligible fish কি না যাচাই করে না। line 242-এর remote সরাসরি এই function-এ পাঠায়। ফলে client-supplied replicated Tool reference process/destroy হওয়ার ঝুঁকি থাকে। এটি memory culprit প্রমাণ নয়, তবে multiplayer stability/data integrity-র গুরুত্বপূর্ণ ত্রুটি।

line 228–229-এ full virtual inventory response; call rate cap/pagination নেই। Inventory বড় হলে repeated response bandwidth ও serialization pressure দিতে পারে। Favourite fish load-এ Tool clone হয়; inventory/equipped cap নেই এই module-এ। মূল packed FishingServer অন্য limit দেয় কি না অজানা।

**সমাধান:** remote input type/ancestry, ownership, eligible fish এবং transition lock; unique server-owned item id। Equipped/favourite physical tools cap; virtual inventory pagination ও request limiter; data limit business rule অনুযায়ী, পুরোনো মাছ মুছে নয়।

**ভালো দিক:** PlayerRemoving-এ VirtualInventories clear হয়; PendingFishSaves clear এবং SaveLocks ব্যবহৃত। তাই এই table-এর cleanup পুরো নেই বলা ভুল। Save/load correctness আলাদা regression test চাই; profiling করার সময় DataStore data মুছবেন না।

## C7 — Static baseline বড়; static size ও leak আলাদা

Workspace-এ ৩৫,২৬৭ instance; ServerStorage-এ ২৫,৩৩৩; ReplicatedStorage-এ ১২,৪০৬। ServerStorage-এর `Other Trass of server storage` একাই ১৩,৪৫২, `PARKMODEL` ৩,৮০৬, `Trees server storage` ২,১২৪। এগুলো unused কি না references ছাড়া বলা যায় না; template হিসেবে ব্যবহৃত হতে পারে।

Selected physical-part classes মিলিয়ে Workspace-এ ১৪,৫২৯ part, যার ৬০৯টিতে Anchored false। Rig/welded assembly/vehicle অন্তর্ভুক্ত; এটি ৬০৯ independent physics assembly নয়। Anchored=false সব part anchor করলে গেম ভেঙে যাবে।

**সমাধান:** unused server backup/model library runtime place থেকে বাদ দেওয়ার আগে dependencies যাচাই; backup আলাদা source control/place-এ। Spawned tool, fish, vehicle, VFX-এর lifecycle ও per-player/global cap। Decorative collision/touch বন্ধ করা যায় কি না যাচাই; physics assemblies-এর profiler trace নিন। Streaming client-এর সহায়তা করে, server-এর পুরো stored world free করে না।

Static ৮০ হাজার instance runtime baseline বাড়ায়, কিন্তু server age-এর সঙ্গে ধারাবাহিক বৃদ্ধি একা ব্যাখ্যা করে না। Mesh/texture asset memory number instance count থেকে হিসাব করা হয়নি।

## C8 — TableLearboard: নিশ্চিত server-side recurring কাজ

`54100_TableLearboard.lua` line 191–193 infinite UI tween; সব player's GUI-তে rows; প্রতি সেকেন্ডে descendants scan, প্রতি ৬০ সেকেন্ডে rebuild ও async refresh। বিস্তারিত Receive report R1।

**সমাধান:** client rendering/countdown/tween, server cached data, single-flight refresh ও name/thumbnail cache। আগের row Destroy আছে—এটি confirmed never-ending row leak নয়।

## C9 — Shutdown script-এর নাম বিভ্রান্তিকর; crash prevention নয়

Path: `ServerScriptService.ServerReceiveSoftSadown`; source `54021_ServerReceiveSoftSadown.lua`।

- line 37: `BindToClose`-এ shutdown শুরু হলে teleport workflow চালায়। **এটি নিজে Receive limit বা daily memory reset করে না; shutdown শুরু করার timer-ও এই readable script-এ নেই।**
- callback-এর ভিতরে আলাদা spawn ও পরে player-zero হওয়া পর্যন্ত অপেক্ষা; Roblox shutdown window সীমিত। Teleport failure/retry handling অসম্পূর্ণ; `P.Content` readiness ধরে নেওয়া হয়।
- `getServerType()` VIPServer ফেরাতে পারে, কিন্তু ServerFactors-এ VIPServer handler নেই; শেষ line-এ nil call হতে পারে। এটি script error—নিজে process crash-এর প্রমাণ নয়।

**সমাধান:** VIP/reserved/public প্রত্যেকটির explicit path; bounded close coordinator; teleport error handling ও player readiness। Scheduled maintenance restart থাকলে কারণ log এবং data save verify; memory leak ঢাকতে প্রতিদিন restart-ই চূড়ান্ত সমাধান নয়। Hard crash/OOM-এ BindToClose চলবে ধরে নির্ভর করা যাবে না।

Zone Panel-এ `zoneSoftRestart` (54013, line 2700 থেকে) আছে: notice → teleport → remaining players kick। Command-triggered restart এবং dashboard-এর `Crashed` একই বিষয় ধরে নেওয়া হয়নি। Admin action timestamp-এর সঙ্গে incident মিলিয়ে দেখতে হবে।

## C10 — Conditional menu clone endpoint: এখন প্রধান কারণ হিসেবে বাদ

`ServerScriptService.Loading And OverHead.MapTeleportServer 2`, `54026_MapTeleportServer_2.lua` line 81–88: ServerStorage-এ `main manu` থাকলে প্রতি invoke-এ workspace clone; limiter/cleanup নেই।

**কিন্তু এই ফাইলে ওই template ServerStorage-এ নেই; `ReplicatedFirst.main manu` আছে।** Readable menu backup local clone করে, পুরোনো InvokeServer code commented। অতএব বর্তমান file থেকে এই endpoint-কে সক্রিয় menu memory leak বলা যায় না। কোনো runtime code template সেখানে রাখলে ঝুঁকি ফেরে। অব্যবহৃত endpoint বাদ বা এক player এক model ও cleanup দিন। Teleport handler-এর full-workspace scan-ও cache করা যায়।

## Opaque code এবং HTTP evidence

সবচেয়ে গুরুত্বপূর্ণ অজানা: `FishingServer` 54023, `BoxingServer` 54090, `MicWireHandler` 17148, Donation 54030, দুই donation board এবং কিছু tool script। নাম দেখে backdoor/crash script বলা হয়নি। Packed code চালানো, license bypass বা remote code fetch করা হয়নি। Donation payload-এর static string decode partial evidence, full readable logic নয়।

Zone Panel externally required license module-এর code file-এর ভিতরে নেই। Screenshot-এ Pastebin/roproxy HTTP আছে, কিন্তু elapsed time ছাড়া spam rate বোঝা যায় না। HTTP request নিজে player Receive নয়; repeated fetch-এ latency/load হতে পারে। এগুলো audit করতে বর্তমান readable vendor source ও request timing দরকার। কোনো endpoint-কে প্রমাণ ছাড়া crash cause বলা হচ্ছে না।

## আগে কী ঠিক করবেন

১. ArmServer input/registry/click budget ও animation wait timeout। FishDataStore tool ownership ও response limits।

২. TableLearboard GUI কাজ client-এ। Admin effects cancellable task/lifecycle ও bounds।

৩. RPS/seat/bike animation ownership cleanup; boxing caches bounded, activation যাচাইসহ।

৪. Unused assets/backups ও dynamic spawn caps; packed Fishing/Boxing/Mic source audit।

৫. একই version-এ baseline এবং একবারে একটি পরিবর্তন; crash rate “শূন্য” প্রতিশ্রুতি নয়।

## যে পরীক্ষায় প্রকৃত কারণ আলাদা হবে

- একই JobId-এর প্রতি ৬০ সেকেন্ডে server age, player count, total server memory, LuaHeap/Instances/PhysicsParts প্রভৃতি উপলব্ধ memory category এবং script/physics time log করুন। প্রতিবার আলাদা server-এর number তুলনা করে leak বলবেন না। Log history সীমিত রাখুন; নতুন অসীম in-memory log তৈরি করবেন না।
- Static snapshot warm-up → steady player count → play loops → leave/rejoin/respawn → cooldown। অন্তত কয়েক ঘণ্টা; ২৪ ঘণ্টার failure-এর জন্য আগের failure window ছাড়িয়ে soak test। FPS/Receive ও player count একসঙ্গে রাখুন।
- Track live counts: workspace descendants, physical fish/tools, active matches, animations/tasks, temporary VFX, pending invites। Full GetDescendants প্রতি frame-এ চালাবেন না।
- Memory ফিরছে না কিন্তু instance স্থির: Lua references/cache/connection ও engine categories দেখুন। Instance বাড়ছে: folder/class অনুযায়ী spawn/destruction trace। Players কমার পরও retained growth গুরুত্বপূর্ণ, কিন্তু allocator cache-এর জন্য total memory সঙ্গে সঙ্গে না কমা একাই leak প্রমাণ নয়।
- কম-memory crash-এর ক্ষেত্রে exact crash timestamp, JobId, engine/place version, server age, error/callstack ও তার আগের action সংগ্রহ করুন। Engine failure হলে Roblox support/bug report-এ ওই evidence দিন; minimal reproduction test copy বানান।
- Last log persist নাও হতে পারে; close-time log বা BindToClose একমাত্র crash recorder নয়। Save/load ও receipt processing-এর regression check রাখুন।

## দেওয়া প্রমাণ ও অক্ষত রাখা ফাইল

Original `.rbxl` SHA-256: `a7db9ec7969bf578ba8dbff2eef1eee694735e44a3cc9d6d423197fe38757a89`। Source extraction read-only; কোনো game source/instance/property বদলানো হয়নি, কিছু publish করা হয়নি। Line number উদ্ধার করা source-এর, obfuscated original হলে line 1 পুরো program হতে পারে। Inventory-তে সব script-এর path/type/disabled/run-context ও inferred role আছে; inferred role behavior verification নয়।

কিছু configuration-এ live-looking Discord webhook আছে। Report-এ secret URL/token প্রকাশ করা হয়নি। এগুলো অন্য কারও কাছে প্রকাশ পেয়ে থাকলে সংশ্লিষ্ট webhook rotate করুন।
