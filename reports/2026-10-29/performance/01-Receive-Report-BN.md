# রিপোর্ট ১ — Receive / replication / client lag

পরীক্ষিত ফাইল: **Bangladeshi Tower 41.rbxl**, ২৯ অক্টোবর ২০২৬।

## সিদ্ধান্ত ও পরীক্ষার সীমা

গেমে অপ্রয়োজনীয় server-side GUI animation, game-event replication এবং বড় replicated asset library পাওয়া গেছে। এগুলো কমানোর নির্দিষ্ট সুযোগ আছে। **কোন script ঠিক কত KB/s পাঠাচ্ছে এবং ৫০–৫৫ KB/s-এর কত শতাংশ তার দায়—ফাইল দেখে মাপা যায় না।** নিচের ক্রমটি তদন্ত/সংশোধনের অগ্রাধিকার; মাপা bandwidth ranking নয়। Roblox Studio বা live server এখানে চালানো হয়নি।

Binary file থেকে ২০৬টি class group ও ৭৯,৪৫৯টি instance পড়া হয়েছে; header-এর সংখ্যার সঙ্গে মিলেছে। সব ১,৪১০টি script source উদ্ধার ও pattern scan করা হয়েছে; ৬৯৫টি পৃথক source। গুরুত্বপূর্ণ readable networking/lifecycle path বিস্তারিত পড়া হয়েছে। এটি প্রতিটি code path runtime-এ পরীক্ষা বা সব obfuscated source পুরোপুরি বোঝার দাবি নয়।

স্ক্রিনশটে Receive average ৫০.২৭–৫৫.২০ KB/s, বর্তমান ৩২.৭০–৪০.৮২ KB/s; Send ২.২১–৩.১৮ KB/s। ৫০ KB/s graph target একটি সর্বজনীন crash/lag সীমা নয়। Receive বেশি মানেই FPS কমার কারণ নিশ্চিত নয়।

## R1 — TableLearboard: সার্ভার থেকে প্রতিটি player's GUI-তে infinite glow tween

**অগ্রাধিকার: প্রথমে। প্রমাণ: code-এ নিশ্চিত; bandwidth প্রভাব মাপতে হবে।**

Studio path: `ServerScriptService.TableTopServer.TableLearboard`। উদ্ধার করা source: `54100_TableLearboard.lua`।

- line 145–152-এ পুরোনো row মুছে নতুন row clone করা হয়।
- line 191–193: `TweenInfo.new(..., -1, true)` দিয়ে `UIStroke.Transparency`-এর অসীম tween server-এ চলে।
- line 201 থেকে StarterGui এবং line 207 থেকে প্রতিটি player's PlayerGui-তে এই GUI বসানো হয়।
- line 220 থেকে countdown update; line 233 ও 239-এর loops প্রতি সেকেন্ডে GUI descendants খোঁজে; line 256-এর loop প্রতি সেকেন্ডে চলে।

ফলে শুধু একটি ছোট leaderboard data payload পাঠানোর বদলে server অনেক GUI object তৈরি/ধ্বংস ও animated property update পরিচালনা করছে। PlayerGui প্রতিটি মালিকের কাছে replicate হয়; সবার private GUI সবাই পায়—এমন নয়। World GUI হলে তার visibility/replication scope আলাদা।

**সংশোধন:** সার্ভার top-10 data cache রাখবে; বদলালে data ও refresh deadline পাঠাবে। LocalScript row, glow tween ও countdown চালাবে। শুধু leaderboard দেখা/খোলা client-কে প্রয়োজনমতো পাঠানো যাবে। অপরিবর্তিত row rebuild না করে diff update করা উচিত। Name/thumbnail cache এবং একসঙ্গে একটিমাত্র refresh-in-flight রাখুন।

**সতর্কতা:** পুরোনো row `Destroy()` করার ব্যবস্থা আছে। তাই এই tween দেখেই “প্রতি মিনিটে নিশ্চিত leak” বলা হচ্ছে না; এটি নিশ্চিত server animation/GUI churn।

**যাচাই:** অন্য সব একই রেখে test copy-তে glow tween বন্ধ করে এবং তারপর পুরো GUI rendering client-এ নিয়ে idle Receive, server script time ও instance churn তুলনা করুন।

## R2 — AdminServer: চালু থাকলে প্রতি Heartbeat-এ replicated character property বদলায়

**অগ্রাধিকার: প্রথম দফা; effect চলার সময় বিশেষভাবে। প্রমাণ: নিশ্চিত conditional আচরণ।**

Path: `ServerScriptService.Admin Panel.AdminServer`; file `53994_AdminServer.lua`।

- line 252: Spin; line 276: WalkBackwards; line 429: DrunkWalk — character root CFrame বারবার বদলায়।
- line 571–577: DiscoMode প্রতি Heartbeat-এ character-এর সব BasePart-এর রং random করে।
- line 642–647: LoopReset Heartbeat callback-এর ভিতরে `task.wait(interval)` দেয়। এতে Heartbeat-এর পরবর্তী callback বন্ধ থাকে না; বহু sleeping callback জমতে পারে।

**সংশোধন:** cosmetic disco client-এ; server থেকে effect start/stop ও seed/time পাঠান। Gameplay movement server-validated রাখুন; সব CFrame কাজ অন্ধভাবে client-এ নেবেন না। LoopReset-কে একটি cancellable timed worker বানান; respawn, effect-off ও leave-এ stop করুন। Admin request-এ rate limit ও tool clone cap দিন।

**সীমা:** admin effect বন্ধ থাকলে ওই callbacks Receive বাড়ানোর ব্যাখ্যা নয়। PlayerRemoving-এ connection cleanup ইতিমধ্যেই আছে; সেটিকে অনুপস্থিত বলা যাবে না।

## R3 — ArmServer: click-এর সঙ্গে সঙ্গে update, server rate cap নেই

Path: `ServerScriptService.ArmServer.ArmServer`; file `54092_ArmServer.lua`।

line 222-এর `ProcessClick`, line 248–249-এর দুই `FireClient`, এবং line 267-এর click handler দেখুন। প্রতিটি গ্রহণ করা click দুই participant-কে score update পাঠায়। Handler-এ server-side click frequency cap নেই; multiplier client থেকে নেওয়া হয়।

**সংশোধন:** server নির্ধারিত click budget; valid finite multiplier/score, server-owned boost; score snapshot সর্বোচ্চ একটি উপযুক্ত cadence-এ batch পাঠানো। শুরুর পরীক্ষার জন্য ১০ Hz snapshot একটি প্রস্তাব, Roblox-এর বাধ্যতামূলক limit নয়। কেবল participant/প্রয়োজনীয় spectator-কে update দিন।

**যাচাই:** স্বাভাবিক match-এর update count ও bytes মাপুন; test environment-এ capped input validation পরীক্ষা করুন। Live game-এ flood test নয়।

## R4 — PianoMain: zone-এ note relay আছে, কিন্তু input budget নেই

Path: `Workspace.Pianos.angelkireina's grand.Scripts.PianoMain`; file `14733_PianoMain.lua`।

line 25–38 note relay, line 41–69 sustain/finish relay। SeatOccupant check এবং `PianoZone:getPlayers()` recipient filtering ইতিমধ্যেই আছে—এটি ভালো। তবে server handler-এ note rate, payload type/size বা note-value bounds-এর পূর্ণ validation নেই। line 73-এর animation handler-এ listener loop-এর ভিতরে একই `PianoAnimation` call হয়।

**সংশোধন:** musician-প্রতি note budget, bounded primitive payload, supported sound/note whitelist; একই note burst একত্র করার পরীক্ষা। Server piano animation একবার চালানো যথেষ্ট হলে recipient সংখ্যার জন্য পুনরাবৃত্তি সরান। বৈধ দ্রুত piano playing যেন না ভাঙে, সেটি পরীক্ষা করুন।

**সীমা:** কেউ piano না বাজালে এটি স্থায়ী idle Receive-এর প্রধান ব্যাখ্যা নয়।

## R5 — RPS / TableServer: cosmetic world/UI animation server-এ

- `ServerScriptService.RPS_Server.RPS_Server`, file `54095_RPS_Server.lua`: line 203–217 billboard image/rotation; line 463–465-এ প্রায় ০.১৫ সেকেন্ড অন্তর পরিবর্তন।
- `ServerScriptService.TableTopServer.TableServer`, file `54098_TableServer.lua`: line 115–119 GUI color tween।

**সংশোধন:** server final result, round id ও start time authoritative রাখবে; client spin/reveal/color animation চালাবে। প্রয়োজনে শুধু কাছের দর্শকদের event পাঠান। শুধু দুই participant-এ পাঠালে world spectators-এর feature ভাঙবে কি না পরীক্ষা করতে হবে।

## R6 — replicated asset library ও streaming: baseline client memory/initial transfer

সেভ করা ফাইলে:

| স্থান | instance সংখ্যা |
|---|---:|
| Workspace | ৩৫,২৬৭ |
| ReplicatedStorage | ১২,৪০৬ |
| ReplicatedFirst | ১,৩৪৭ |
| StarterGui | ২,৮৫৫ |
| ServerStorage | ২৫,৩৩৩ |

ReplicatedStorage-এ `FishingRodSystem` ৬,২৪৪, `ButterflyAnim` ১,৮০৩, `Tools` ১,১৩৬ এবং `VFX` ৯৬৮ instance। সেখানে ২,২৫০ ParticleEmitter আছে; **storage-এ থাকা সব emitter render/emit করছে, এমন নয়।** Workspace-এ ৯,৪৮৩ MeshPart, ৪,৮৫৮ SurfaceAppearance, ৩৬৪ ParticleEmitter (৩৩৯টির Enabled true) এবং ২৩ Humanoid আছে। দূরত্ব/culling-এর কারণে সব একসঙ্গে render হয় না। Counts asset bytes বা GPU memory-এর পরিমাপ নয়।

`Workspace.StreamingEnabled = true`, `StreamingMinRadius = 64`, `StreamingTargetRadius = 500` ইতিমধ্যেই আছে। `Workspace.Butterfly` subtree-তে ৭০৯ instance; root ও nested model-এ Persistent mode ব্যবহৃত। ReplicatedStorage-কে Workspace streaming দিয়ে unload করা যায় না।

**সংশোধন:** যে template client-এর দরকার নেই তা server-only রাখার সম্ভাবনা যাচাই করুন; পুরো Tools/FishingRodSystem সরাবেন না—বর্তমান client `WaitForChild`/require/template reference ভেঙে যাবে। Client visual assets প্রয়োজনমতো ভাগ করে দিন। Unused library ও StarterGui বাদ দিন। Persistent decoration সত্যিই সর্বদা দরকার কি না পরীক্ষা করুন। Radius পরীক্ষায়, যেমন ৫০০ থেকে ২৫৬, gameplay, teleport, NPC ও stream reload ঠিক আছে কি না যাচাই করতে হবে।

**পার্থক্য:** এগুলো initial transfer ও client memory-এর বড় সম্ভাব্য কারণ; static library থাকলেই প্রতি সেকেন্ডে সেই সব bytes আবার পাঠানো হয় না। Streaming client load কমায়; server-এর পুরো world memory একইভাবে unload করে না।

## যেগুলোকে প্রমাণ ছাড়া Receive-এর কারণ বলা যাবে না

- `ButterflyClient`/`ButterflyAnimator` client animation; board floating scripts, MusicDisplay ও head movement-এর অনেক `Script`-এ **RunContext=Client**। Source-এ tween/Heartbeat আছে মানেই server network নয়।
- `TypingServer` state-change throttle (০.২৫ সেকেন্ড) ও leave cleanup করে; `EmojiServer` cooldown ও ৬০-stud recipient filter করে; `VoiceZoneServer` cell বদলালে তবেই attribute লেখে। এগুলো আগে ভাঙার অগ্রাধিকার নয়।
- Dance `Sync`/`CarryServer`-এ validation, rate limiting/Janitor-ভিত্তিক cleanup আছে। Dance feature মুছে ফেলাকে প্রথম সমাধান ধরা হয়নি।
- DonationServer-এর `FireAllClients` মূলত donation/effect-triggered; এর অস্তিত্ব মানেই constant spam নয়। Client-এ বড় VFX তৈরি হলে FPS/memory খারাপ হতে পারে, ছোট event-এর bandwidth কম হলেও।
- screenshot Network tab-এর server HTTP call player-এর replication Receive-এর হিসাব নয়। DataStore budget মান performed request count নয়।
- `Zone Panel`-এর `10405/s` script rate-কে remote packet count বলা যাবে না। Panel-এর দুই presence loop আছে (line 6238 ও 8129); ৪৫/৩০ সেকেন্ডের কাজ একত্র করা যায়, কিন্তু এতে ৫০ KB/s Receive সমাধান প্রমাণিত নয়।

## গুরুত্বপূর্ণ অজানা অংশ

`FishingServer` (54023), `BoxingServer` (54090), `MicWireHandler` (17148), donation main ও board scripts packed/obfuscated। এদের সম্পূর্ণ branch, remote frequency, wire lifecycle ও memory cleanup readable source ছাড়া নিশ্চিত audit করা যায়নি। পুরোনো readable backups থাকলেও বর্তমান packed code-এর সঙ্গে সমান প্রমাণ করা যায়নি। Donation VM payload থেকে কিছু string static decode করা হয়েছে; code চালানো হয়নি। এতে request frequency বোঝা যায় না। Screenshot-এর repeated Pastebin endpoint কোনো নির্দিষ্ট script-কে নিশ্চিতভাবে দায়ী করার মতো source evidence পাওয়া যায়নি।

ফলে বর্তমানে “Receive-এর একমাত্র culprit এই script”—এমন দাবি গ্রহণযোগ্য নয়। Vendor/আপনার কাছ থেকে ওই বর্তমান সংস্করণের readable source দরকার।

## Receive কমেছে কি না যাচাইয়ের পরিকল্পনা

১. একই place version, সমান player count/অবস্থান, একই graphics/device, একই warm-up সময়ে ৩–৫ মিনিটের baseline নিন। Join/asset loading ও steady-state আলাদা করুন। Receive average/p95, Send, FPS/CPU/GPU, data ping, server memory লিখুন।

২. Test copy-তে একবারে একটি feature বদলান: TableLearboard glow/render → admin effects → RPS/Table cosmetic → piano/Arm update cadence। ছোট player test এবং ভরা server test আলাদা রাখুন।

৩. Server-side remote send call count ও estimated payload size আলাদা মাপুন। এগুলো wire-level exact bytes নয়। Instance/property/physics replication ও voice-সংক্রান্ত traffic আলাদা নজর দিন। Roblox profiling-এ উপলব্ধ network/replication data-এর সঙ্গে মিলিয়ে নিন।

৪. ৫০% বা কোনো নির্দিষ্ট KB/s হ্রাস আগে থেকে প্রতিশ্রুতি নয়। উন্নতির শর্ত: একই gameplay-এ কম Receive, কোনো missing event নয়, acceptable FPS/ping এবং memory স্থির থাকা।

কোনো game source বা place file পরিবর্তন/প্রকাশ করা হয়নি। এটি static evidence ও প্রস্তাবিত সমাধানের রিপোর্ট।
