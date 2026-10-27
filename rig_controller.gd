extends Node2D
## Qiongqi v9: rigid layered Bone2D prototype, not weighted skinning.
signal attack_hit
signal dive_impact
signal death_finished

@onready var player: AnimationPlayer = $QiongqiRig/AnimationPlayer
@onready var rig: Node2D = $QiongqiRig
@onready var status: Label = $CanvasLayer/Help
var state: String = "idle"
var dead := false
var lock_action := false
var elapsed := 0.0

const ACTIONS := ["idle", "fly", "dive", "attack", "hurt", "death"]
const DURATION := {"idle":2.0,"fly":1.2,"dive":0.75,"attack":0.8,"hurt":0.5,"death":1.4}
const AMPLITUDE := {
    "idle": {"Body":0.012,"WingLeft":-0.09,"WingRight":0.10,"Head":0.03,"Tail":0.10,"FrontLeftLeg":0.02,"FrontRightLeg":-0.02},
    "fly": {"Body":0.025,"WingLeft":-0.34,"WingRight":0.36,"Head":0.04,"Tail":0.18,"FrontLeftLeg":0.09,"FrontRightLeg":-0.09,"BackLeftLeg":-0.06,"BackRightLeg":0.06},
    "dive": {"Body":-0.16,"WingLeft":0.42,"WingRight":-0.38,"Head":-0.12,"Tail":-0.25,"FrontLeftLeg":0.20,"FrontRightLeg":0.22,"BackLeftLeg":0.12,"BackRightLeg":0.12},
    "attack": {"Body":-0.08,"WingLeft":-0.16,"WingRight":0.19,"Head":0.25,"Tail":0.15,"FrontLeftLeg":-0.32,"FrontRightLeg":-0.43,"BackLeftLeg":0.06},
    "hurt": {"Body":0.12,"WingLeft":0.20,"WingRight":-0.20,"Head":-0.18,"Tail":-0.13,"FrontLeftLeg":0.12,"FrontRightLeg":0.12},
    "death": {"Body":0.33,"WingLeft":0.48,"WingRight":-0.47,"Head":0.32,"Tail":-0.37,"FrontLeftLeg":0.36,"FrontRightLeg":0.38,"BackLeftLeg":0.25,"BackRightLeg":0.25}
}

func _ready() -> void:
    var lib := AnimationLibrary.new()
    for action in ACTIONS:
        lib.add_animation(action, _make_animation(action))
    player.add_animation_library("", lib)
    player.animation_finished.connect(_on_finished)
    play_state("idle")

func _make_animation(action: String) -> Animation:
    var a := Animation.new()
    a.length = DURATION[action]
    a.loop_mode = Animation.LOOP_LINEAR if action in ["idle","fly"] else Animation.LOOP_NONE
    var peaks: Array = [0.0, 0.55, 1.0, 0.45, 0.0] if action in ["idle","fly"] else [0.0, 0.20, 1.0, 0.60, 0.0]
    if action == "death":
        peaks = [0.0, 0.4, 0.85, 1.0, 1.0]
    for bone_name in AMPLITUDE[action]:
        var path: String = "Skeleton2D/Body" + ("" if bone_name == "Body" else "/" + str(bone_name)) + ":rotation"
        var index := a.add_track(Animation.TYPE_VALUE)
        a.track_set_path(index, NodePath(path))
        a.track_set_interpolation_type(index, Animation.INTERPOLATION_CUBIC)
        var amp: float = AMPLITUDE[action][bone_name]
        for i in range(peaks.size()):
            var phase: float = float(i) / float(peaks.size()-1)
            var v: float = amp * peaks[i]
            if action in ["idle","fly"]:
                v = amp * [0.0,1.0,0.0,-1.0,0.0][i]
            a.track_insert_key(index, phase * a.length, v)
    return a

func play_state(next: String) -> void:
    if not next in ACTIONS or dead and next != "death":
        return
    if lock_action and next not in ["hurt","death"]:
        return
    if next == "death":
        dead = true
    lock_action = next in ["dive","attack","hurt","death"]
    state = next
    elapsed = 0.0
    player.play(next, 0.12)
    _update_label()

func _process(delta: float) -> void:
    if not lock_action:
        return
    elapsed += delta
    if state == "attack" and elapsed >= 0.42 and elapsed - delta < 0.42:
        attack_hit.emit()
    if state == "dive" and elapsed >= 0.54 and elapsed - delta < 0.54:
        dive_impact.emit()

func _on_finished(animation_name: StringName) -> void:
    if animation_name == "death":
        death_finished.emit()
        return
    if animation_name in ["attack","dive","hurt"]:
        lock_action = false
        play_state("fly" if animation_name == "dive" else "idle")

func _update_label() -> void:
    status.text = "Qiongqi v9 | 1 Idle  2 Fly  3 Dive  4 Attack  5 Hurt  6 Death  R Reset | " + state

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode >= KEY_1 and event.keycode <= KEY_6:
            play_state(ACTIONS[event.keycode - KEY_1])
