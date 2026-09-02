CATCOIN GAME DEV KIT
====================

Purpose
-------
This kit packages the key CatCoin Runner planning documents in a handoff-friendly format for developers and AI coding agents.

Recommended Execution Order
---------------------------
1. Read: catcoin_game_architecture_prompt.txt
2. Read: catcoin_content_creation_prompt.txt
3. Read: 6_procedural_level_generation_bible.txt
4. Read: 7_catcoin_balancing_and_reward_economy_bible.txt
5. Read: 8_catcoin_art_production_pipeline.txt

What Each File Does
-------------------
catcoin_game_architecture_prompt.txt
- Flutter + Flame architecture
- FastAPI integration
- reward ledger model
- anti-cheat expectations
- downloadable game pack approach

catcoin_content_creation_prompt.txt
- CatCoin mascot art direction
- transparent sprite requirements
- animation requirements
- enemy / collectible / tile requirements

6_procedural_level_generation_bible.txt
- chunk-based spawning
- coin trails
- obstacle fairness
- difficulty ramp

7_catcoin_balancing_and_reward_economy_bible.txt
- catoshi reward model
- daily caps
- anti-inflation controls
- server validation expectations

8_catcoin_art_production_pipeline.txt
- art workflow
- review and validation rules
- naming conventions
- Flame compatibility checks
- asset pack versioning

Suggested Build Flow
--------------------
Phase 1: Architecture
- set up Flutter module and Flame integration
- add launcher screen
- add downloadable asset pack flow
- wire FastAPI session endpoints

Phase 2: Gameplay MVP
- player controller
- coin collection
- enemies
- turbo meter
- HUD
- procedural chunks

Phase 3: Art Integration
- replace placeholder art
- validate sprite sheets
- package production assets

Phase 4: Economy & Validation
- server-side score validation
- reward ledger posting
- daily cap logic
- QA and balancing

Included Folder Templates
-------------------------
project_templates/flutter_flame_structure.txt
- suggested code module layout

project_templates/asset_pack_structure.txt
- suggested downloadable asset pack layout

project_templates/api_contract_stub.txt
- start-session / submit-session contract outline

Notes
-----
- This game is an add-on inside the existing CatCoin mining app.
- The main app should stay lightweight.
- Game content should download on first launch.
- 1 in-game coin = 1 catoshi.
- Session earnings are stored separately in a game reward ledger.
