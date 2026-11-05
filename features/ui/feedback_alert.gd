extends AudioStreamPlayer
## Short placeholder alert; replace the stream in the Inspector with final audio.
func _ready() -> void:
	if stream != null:
		return
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var samples := PackedByteArray()
	var count := 3969
	samples.resize(count * 2)
	for index in count:
		var envelope := sin(PI * float(index) / count)
		var sample := sin(TAU * 330.0 * index / sound.mix_rate) * envelope * 16000
		samples.encode_s16(index * 2, int(sample))
	sound.data = samples
	stream = sound
