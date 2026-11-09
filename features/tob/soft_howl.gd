extends AudioStreamPlayer
## Quiet synthesized placeholder; a final recording can be assigned in Inspector.
func _ready() -> void:
	if stream != null:
		return
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(sound.mix_rate * 2)
	var phase := 0.0
	for index in sound.mix_rate:
		var time := float(index) / sound.mix_rate
		phase += TAU * (240.0 + sin(PI * time) * 130.0) / sound.mix_rate
		var sample := sin(phase) * sin(PI * time) * 10000
		samples.encode_s16(index * 2, int(sample))
	sound.data = samples
	stream = sound
