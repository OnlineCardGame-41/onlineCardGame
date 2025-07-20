### Is the product complete? Which parts are done and which aren’t done?  
The product is functionally complete, with core gameplay mechanics fully implemented, including hosting/joining multiplayer sessions, card interactions, and a working build. Documentation, such as the README and backlogs, is in place, covering setup and project structure. Some potential future features (like MVP4/MVP5 expansions) weren’t prioritized, but the current version delivers a polished, playable experience.  

### Is the customer using the product? How often? In what way? If not, why not?  
The customer hasn’t integrated the product into regular use, primarily due to their unfamiliarity with Godot—the engine powering the game. While they tested the build successfully, their long-term engagement would require adapting to Godot, which isn’t aligned with their current interests (they prefer tabletop or other engines).  

### Has the customer deployed the product on their side?  
They’ve accessed the build via GitHub Actions but noted the deployment process could be more user-friendly for non-technical users. Minor tweaks to the README (e.g., clearer artifact download instructions) would streamline this.  

### What measures need to be taken to fully transition the product?  
To ease transition, the team could:  
- Refine the README with simpler setup steps and a gameplay guide.  
- Add a quick-reference rulesheet (embedded or separate).  
- Provide a pre-packaged executable for one-click launches.  

### What are the customer’s plans for the product after delivery?  
The customer appreciates the team’s work but doesn’t plan to continue development in Godot. They’d consider collaboration if the project shifted to tabletop or a different engine.  

### How to increase the chance that it’ll be useful after final delivery?  
Ensuring the game is easily deployable and well-documented (e.g., adding a gameplay tutorial or video demo) would boost its longevity. A standalone HTML guide (as the customer suggested) could further enhance accessibility.  

### Customer feedback on your README: Is everything clear?  
The README is thorough but could simplify:  
- Replace technical terms like "latest green run" with plain language (e.g., "Download the latest stable build here").  
- Remove informal jokes to maintain professionalism.  

### Are they able to launch/deploy using your instructions?  
Yes, though the process required minor troubleshooting. Clearer labeling in GitHub Actions (e.g., "Download Game Build") would help.  

### What two other sections should be added to the README?  
1. Quickstart Guide: A step-by-step gameplay primer (how to host/join, basic rules).  
2. Future Roadmap: Briefly outline unrealized ideas (MVP4/MVP5) for inspiration.


Speaker 1:
00:00:11 — Look, you have a product on Gudot. I just don’t know Gudot at all. You have good ideas—at least, first and foremost, Katya, her game design, and so on. For me, what would be interesting is to continue working on some kind of game, primarily a board game.
Speaker 4:
00:00:32 — The thing is, I don’t have Megadot, I just have an Excel spreadsheet.
Speaker 1:
00:00:38 — Right. It’s just that, for me, of course, it would be interesting to have some kind of product where I could immediately work on both a digital and a physical version. But the issue is that I don’t know Godot specifically, so purely from my own internal interest, maintaining this isn’t something I’m super excited about. I mean, I’d basically have to properly learn Godot to keep supporting it.
00:01:08 — I can’t leave you hanging, unsure whether to work on it or not. So, it’s up to you to decide what you want to do moving forward—whether to keep working on it or not, whether to think about it or not. But as I understand, not everyone would want to, so it’s more about your own decision. For me, the main problem is Godot, since I don’t know it.
00:01:38 — It’s been pleasant working with you, but within this limitation. Next: How to increase the chance that it will be useful after the final delivery? Again, that’s not a question for me—that’s for you to answer. Okay, next. Customer feedback on your README. Customer feedback. Is everything clear? What can be improved? Right away, regarding what can be improved...
00:02:08 — You have instructions on how to download it. Here it says: Open the Actions workflow and select the latest green run. Honestly, I looked at it and thought, Last update: "Update README." I figured, Well, it probably won’t be there. Only later did I realize I had to click and look inside the artifacts.
00:02:35 — But it wasn’t as obvious as it could’ve been. I get that for some, it might be an issue of understanding GitHub. But for a random person, it might make sense to explain it a bit more. That’s my personal opinion. I don’t know how fair or unfair that actually is.
00:03:01 — But I have this gut feeling that latest green run might not be entirely obvious. Next. Everything else is clear. What’s this? I’m not copying and pasting without reading? What is this? Oh. A joke. Got it. But I think you’ll have to cut that joke, or your supervisor might smack you upside the head at some point.
00:03:32 — I’d remove it, since it’s the end of the project—better to play it safe. Clear? If you liked it, then no problem at all. Okay. So, overall, the project itself seems clear.
00:03:58 — Well, more precisely, the documentation. I’ll open some things just in case. Oh boy. I’m not touching that. Looking at all your backlogs... Again, as you understand, this is all part of the SIG requirements. And evaluating the content of all this...
00:04:25 — That’s not really my job as much as it is the supervisor’s. Simply because Performance Efficiency, Compatibility—these were all part of your SIG requirements. So it’s not really for me to evaluate. There’s some image here. Well, yeah, you have all this in the README too, so...
00:04:58 — I’m not entirely sure what I could even evaluate here. It all seems clear. Are they able to launch/deploy using your instructions? The instructions exist, but about the instructions, I already gave my feedback—I’d make them a bit clearer for the average person. Next. What two other sections the customer would like to be included?
00:05:26 — Okay, my only note is... I’m comparing this to another team, and I don’t know what your SIG requirements were, what they had that you don’t... or at least, I don’t see it. For example, you had some plans for MVP4, MVP5, and so on. They had that explicitly, you don’t—so I don’t know if you need it.
00:05:57 — Just not sure how it compares. Poof. What else? Probably... If this is a README file, it might make sense to not just explain how to launch it but also how to actually play the game inside. Because, sure, the Host and Join buttons are interesting, but you also have...
00:06:29 — Yeah, you have some ping button, something else. At the very least, it’d be good to explain how to set up a proper game, how it works. Somewhere, you should also include either the rules or something close to them.
00:06:51 — It’d probably be better if there was at least some understanding. It’d be nicer, more polished. That’s what I’d add, I guess. Now, let’s switch to your questions for me, since I might’ve missed something. Everyone’s mics are off.
00:07:24 — That’s unsettling.
Speaker 2:
00:07:25 — Well, I don’t do SIG, I don’t know how to give feedback on it, so to speak.
Speaker 1:
00:07:32 — Got it.
Speaker 2:
00:07:33 — Alina, can you drop a question in the chat? Or Daniil?
Speaker 4:
00:07:39 — I didn’t catch that.
Speaker 2:
00:07:42 — Do you have any other questions?
Speaker 3:
00:07:45 — I don’t have any.
Speaker 1:
00:07:49 — Because, regarding SIG and this task, I think I’ve answered all your points. It’s just that if you’re sitting there being taught all sorts of things, that’s one thing. But in the README, they sometimes want things I’m not even sure should be there.
00:08:20 — Like, how many of those nuances should there be? Well, first and foremost, it should cover usage notes. And you have those.
00:08:47 — They asked you for a lot of attacks, so for users, it’d probably make sense... Okay, I get it, fine, I won’t say it. Well, overall, I’ve said the README could be more user-friendly.
00:09:15 — I had a good example with one game—it even came with an HTML file that ran locally in the browser and explained everything really well. Like, the game had 10 monsters, each with their own weaknesses and strengths, and it was all written out for each one. Not too long, but very informative.
00:09:45 — So even as a player, it was really nice, really helpful. Probably the best example of a useful addition to a game I’ve seen. It wasn’t part of the README, it was alongside it. That’s probably the gold standard for game supplements—something genuinely useful. That’s the most I could suggest as ideal, but you already have a lot.
00:10:16 — So, like, a gameplay description in the README? Look. A direct gameplay description isn’t as important—that could even go in a separate file. But explaining how to launch the game—what the host is supposed to do, what the players do—that’s what I’d include. Because, well, you never know, it might not be obvious to a complete beginner.
00:10:51 — How to move cards and so on—at best, that could be the game rules, or it could be written inside the game itself. But how to create a game and so on—putting that inside the game itself doesn’t seem great from a UX perspective. If a user doesn’t know how to create a game, they’ll find the file.
00:11:22 — This step feels more important to include in the README because it’s more technical than the gameplay itself. So, yeah. Any other questions? Or, well, it seems like the questions are done, but...
Speaker 2:
00:11:34 — There’s still a question. We’re meeting tomorrow. Let me step in. No, no, you sit. Well, I have a question. We’re meeting tomorrow. We’re going over the game, figuring things out. And we’re preparing before the main day, right?
Speaker 1:
00:11:56 — Okay, first, I’m not sure who that’s directed at. Second...
Speaker 2:
00:11:59 — It’s a question for you, Timofey. Tomorrow, we’re supposed to formally show you the final build of the working game—what we demoed at the dump. Are we meeting tomorrow or not?
Speaker 1:
00:12:10 — Look, as soon as you’re done, let me know. Tomorrow, I’m working until the evening, so I’ll be free around 6 PM. Dinner is at 6, so let’s aim for around 7 PM—I’ll be free then. So at 7 PM, I can easily hop on a call with you, no problem.
00:12:40 — The main thing is, show me something tomorrow. That’s way more important. I’m working tomorrow, but I’m free at 7. So yeah, if you finish tomorrow, we should at least meet. Because, as I’ve found out—not sure if I should even tell you this—I also have certain criteria to evaluate your work, and I need to see if you meet them.
00:13:22 — Once you’ve finished merging, of course. If you merge. So I’m really counting on you merging tomorrow.
Speaker 2:
00:13:33 — Got it, we’ll merge tomorrow in the city. Yeah, so... This reminds me of that one all-nighter. And the night after, twenty times over. Well, I guess that’s it.
Speaker 1:
00:13:52 — Yeah, I guess so.
Speaker 2:
00:13:54 — Mm-hmm. Tomorrow, we’ll still be recording the video for the showcase. And that video will be in the evening. And you’re free again at...? Seven PM. Seven PM. Okay. So we have tonight and most of tomorrow to work.
Speaker 1:
00:14:17 — That’s it? Okay, okay, okay. Just kidding.
Speaker 2:
00:14:22 — I’m just psyching myself up. Alright, no problem.
Speaker 1:
00:14:28 — Okay, hold on. I have one technical question that’s not so much worrying me as it is piquing my curiosity. Everyone came to the meeting except one person. Did he vanish again? Initially, it seemed... Or am I imagining it?
Speaker 3:
00:14:50 — Maybe he’s still at work. That’s my guess. He was at work earlier today. But I’m not sure.
Speaker 1:
00:14:59 — Alright. It’s just that when you see a team member literally twice the entire time, questions arise.
Speaker 4:
00:15:12 — But Vova actually did a lot. He worked a ton—at night. He really did a lot.
Speaker 1:
00:15:21 — I’m not arguing. It’s just... At the end of the day, you’ll be writing peer reviews anyway. For me, the main thing is that the person is working. And second... What was second... Well...
Speaker 4:
00:15:40 — Would you like to at least see the person working?
Speaker 1:
00:15:48 — Exactly, because I’m asking, Show me what you did, and when the person isn’t here, I can’t ask. So yeah. Alright, in that case, see you tomorrow, I guess.
Speaker 4:
00:16:05 — Yeah, probably.
Speaker 1:
00:16:09 — Huh? Oh! Huh? Did you redo the cheekbones?
Speaker 4:
00:16:15 — Yeah, the ones you marked—I redid them, they’re all in the spreadsheet.
Speaker 1:
00:16:22 — Got it, I’ll check now if it’s the same spreadsheet.
Speaker 5:
00:16:28 — Yeah, it’s the same one. I understood what you meant about the health mechanic, but I implemented it a bit differently.
Speaker 1:
00:16:37 — Okay, I’ll check now. All good.
Speaker 5:
00:16:40 — If anything, you can message me.
Speaker 1:
00:16:45 — Alright, let’s take a look.
