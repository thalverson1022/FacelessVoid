extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var registry := BuildContentRegistry.test_mode()
 for folder in ["full35_random_bosses_d018","full35_isolated_mechanics_d018"]:
  var path: String = "res://reports/balance/"+folder
  var bosses: Array = JSON.parse_string(FileAccess.get_file_as_string(path+"/bosses.json")).bosses
  var rows := []
  for boss in bosses:
   for tree in ["bladedancer","thief","assassin","shadow"]:
    var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path+"/00_"+tree+".json"))
    var payload: Dictionary = baseline.foundation_snapshot.build
    payload.build_schema_version = int(payload.build_schema_version)
    payload.earned_talent_points = int(payload.earned_talent_points)
    for id in payload.talent_ranks: payload.talent_ranks[id] = int(payload.talent_ranks[id])
    var decoded := BuildSaveCodec.decode(payload,registry)
    assert(decoded.error == "",decoded.error)
    var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
    var resolved := BuildResolver.resolve_ranked_build(decoded["class"],decoded.model,gear,0)
    var requested: Array[Skill] = []
    for id in decoded.rotation_ids:
     var skill := Skill.new()
     skill.id = id
     requested.append(skill)
    var rotation: Array[Skill] = BuildResolver.normalize_rotation(requested,resolved.skills).rotation
    var monster := GeneratedMonsterDraft.from_dictionary(boss.draft).to_monster()
    var result := CombatResolver.resolve(rotation,resolved.stats,monster,30000,1)
    var native: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path+"/%02d_%s.json"%[int(boss.index)+1,tree]))
    assert(is_equal_approx(result.dps,float(native.samples[0].dps)),"Diagnostic/native parity")
    var stuns := 0
    var interrupts := 0
    var skipped := 0
    for event in result.cast_events:
     if event.stun_duration_ms > 0: stuns += 1
     if event.was_interrupted: interrupts += 1
     if event.interrupt_skipped: skipped += 1
    rows.append({"boss_index":boss.index,"tree":tree,"seed":1,"dps":result.dps,"stun_events":stuns,"interrupt_events":interrupts,"interrupt_skips":skipped,"gold_stolen":result.gold_stolen,"combat_summary":Lab._combat_summary(1,result)})
  SaveSystem.write_json(path+"/diagnostics_seed1.json",{"rows":rows,"all_seed1_dps_match_native":true})
 print("Diagnostics/native seed-1 parity passed for every matchup")
 quit()

