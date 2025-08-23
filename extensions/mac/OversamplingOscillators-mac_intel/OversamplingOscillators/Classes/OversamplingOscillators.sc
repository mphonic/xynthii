VariableRamp : UGen {
	*ar { |freq=10, trig_reset=0, mul = 1, add = 0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(trig_reset.rate!='audio'){trig_reset = K2A.ar(trig_reset)};
		^this.multiNew('audio', freq, trig_reset).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

// AccumRamp : UGen {
// 	*ar { |slope=0, offset_in = 0, trig_reset=0, mul = 1, add = 0|
// 		if(slope.rate!='audio'){slope = K2A.ar(slope)};
// 		if(offset_in.rate!='audio'){offset_in = K2A.ar(offset_in)};
// 		if(trig_reset.rate!='audio'){trig_reset = K2A.ar(trig_reset)};
// 		^this.multiNew('audio', freq, trig_reset).madd(mul, add);
// 	}

// 	checkInputs {
// 		/* TODO */
// 		^this.checkValidInputs;
// 	}
// }

SawOS : UGen {
	*ar { |freq=440, phase=0, oversample=1, mul = 1, add = 0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		^this.multiNew('audio', freq, phase, oversample).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

SawOS8 : UGen {
	*ar { |freq=440, phase=0, oversample=1, mul = 1, add = 0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		^this.multiNew('audio', freq, phase, oversample).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

SinOscOS : UGen {
	*ar { |freq=440, phase=0, oversample=1, mul = 1, add = 0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		^this.multiNew('audio', freq, phase, oversample).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

PMOscOS : UGen {//CarFreq, ModFreq, PMMul, PMModPhase, OverSample
	*ar { |carFreq=440, modFreq=220, pmMul=1, pmModPhase=0, oversample=1, mul = 1, add = 0|
		if(carFreq.rate!='audio'){carFreq = K2A.ar(carFreq)};
		if(modFreq.rate!='audio'){modFreq = K2A.ar(modFreq)};
		if(pmMul.rate!='audio'){pmMul = K2A.ar(pmMul)};
		if(pmModPhase.rate!='audio'){pmModPhase = K2A.ar(pmModPhase)};
		^this.multiNew('audio', carFreq, modFreq, pmMul, pmModPhase, oversample).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

FM7OS : MultiOutUGen  {
	*numOperators { ^6 }
	*ar { | ctlMatrix, modMatrix, oversample=4, mul=1, add=0 |
		ctlMatrix = (ctlMatrix ?? { this.controlMatrix })
		.collect{|item|
			if(item[0].rate!='audio'){item[0] = K2A.ar(item[0])};
			if(item[2].rate!='audio'){item[2] = K2A.ar(item[2])};
			item
		}.flatten(1);
		modMatrix = (modMatrix ?? { this.modMatrix }).flatten(1)
		.collect{|item|
			if(item.rate!='audio'){item = K2A.ar(item)};
			item
		};
		^this.multiNewList(
			['audio']
			++ ctlMatrix
			++ modMatrix
			++ oversample
		).madd(mul,add)
	}

	init { | ... args |
		inputs = args;
		^this.initOutputs(this.class.numOperators, rate)
	}
	checkInputs {
		^this.checkValidInputs;
	}
}

FM7aOS : MultiOutUGen  {
	*ar { | ctlMatrix, modMatrix, synthTypes, oversample=4, mul=1, add=0 |
		ctlMatrix = (ctlMatrix ?? { this.controlMatrix })
		.collect{|item|
			if(item.rate!='audio'){item = K2A.ar(item)};
			item
		};
		synthTypes.do{|type,i| modMatrix[i][i] = type};
		modMatrix.postln;
		modMatrix = modMatrix.flatten(1)
		.collect{|item|
			if(item.rate!='audio'){item = K2A.ar(item)};
			item
		};
		^this.multiNewList(
			['audio']
			++ ctlMatrix
			++ modMatrix
			++ oversample
		).madd(mul,add)
	}

	init { | ... args |
		inputs = args;
		^this.initOutputs(4, rate)
	}
	checkInputs {
		^this.checkValidInputs;
	}
}

FM7bOS : MultiOutUGen  {
*ar { | ctlMatrix, modMatrix, synthTypes, oversample=4, mul=1, add=0 |
		ctlMatrix = (ctlMatrix ?? { this.controlMatrix })
		.collect{|item|
			if(item.rate!='audio'){item = K2A.ar(item)};
			item
		};
		synthTypes.do{|type,i| modMatrix[i][i] = type};
		modMatrix.postln;
		modMatrix = modMatrix.flatten(1)
		.collect{|item|
			if(item.rate!='audio'){item = K2A.ar(item)};
			item
		};
		^this.multiNewList(
			['audio']
			++ ctlMatrix
			++ modMatrix
			++ oversample
		).madd(mul,add)
	}

	init { | ... args |
		inputs = args;
		^this.initOutputs(4, rate)
	}
	checkInputs {
		^this.checkValidInputs;
	}
}

PM7OS : MultiOutUGen {
	*numOperators { ^6 }
	*numControls { ^3 }
	*controlArraySize { ^this.numControls * this.numOperators }
	*modArraySize { ^this.numOperators.squared }

	*controlMatrix { | ... args |
		var matrix;
		matrix = Array.fill2D(this.numOperators, this.numControls, 0);
		args.do { | x |
			matrix[x[0]] = x.copyToEnd(1);
		};
		^matrix
	}
	*modMatrix { | ... args |
		var matrix;
		matrix = Array.fill2D(this.numOperators, this.numOperators, 0);
		args.do { | x |
			matrix[x[0]][x[1]] = x[2];
		};
		^matrix
	}

	*algoSpec { | algo, feedback=0.0 |
		var matrix;
		matrix = this.modMatrix;
		^[
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 3, 1],
					[3, 4, 1],
					[4, 5, 1],
					[5, 5, feedback]
				),  [0, 2]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[1, 1, feedback],
					[2, 3, 1],
					[3, 4, 1],
					[4, 5, 1]
				),  [0, 2]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[1, 2, 1],
					[3, 4, 1],
					[4, 5, 1],
					[5, 5, feedback]
				),  [0, 3]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[1, 2, 1],
					[3, 4, 1],
					[4, 5, 1],
					[5, 3, feedback]
				),  [0, 3]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 3, 1],
					[5, 5, feedback],
				),  [0, 2, 4]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 3, 1],
					[5, 4, feedback],
				),  [0, 2, 4]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 3, 1],
					[2, 4, 1],
					[4, 5, 1],
					[5, 5, feedback],
				),  [0, 2]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 3, 1],
					[2, 4, 1],
					[4, 5, 1],
					[3, 3, feedback],
				),  [0, 2]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 3, 1],
					[2, 4, 1],
					[4, 5, 1],
					[1, 1, feedback],
				),  [0, 2]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[1, 2, 1],
					[3, 4, 1],
					[3, 5, 1],
					[2, 2, feedback],
				),  [0, 3]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[1, 2, 1],
					[3, 4, 1],
					[3, 5, 1],
					[5, 5, feedback],
				),  [0, 3]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[1, 2, 1],
					[2, 3, 1],
					[2, 4, 1],
					[2, 5, 1],
					[2, 2, feedback],
				),  [0, 2]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[1, 2, 1],
					[2, 3, 1],
					[2, 4, 1],
					[2, 5, 1],
					[5, 5, feedback],
				),  [0, 2]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 3, 1],
					[2, 3, 1],
					[3, 4, 1],
					[3, 5, 1],
					[5, 5, feedback],
				),  [0, 2]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 3, 1],
					[2, 3, 1],
					[3, 4, 1],
					[3, 5, 1],
					[1, 1, feedback],
				),  [0, 2]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[0, 2, 1],
					[0, 4, 1],
					[2, 3, 1],
					[4, 5, 1],
					[5, 5, feedback],
				),  [0]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[0, 2, 1],
					[0, 4, 1],
					[2, 3, 1],
					[4, 5, 1],
					[1, 1, feedback],
				),  [0]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[0, 2, 1],
					[0, 3, 1],
					[3, 4, 1],
					[4, 5, 1],
					[2, 2, feedback],
				),  [0]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[1, 2, 1],
					[3, 5, 1],
					[4, 5, 1],
					[5, 5, feedback],
				),  [0, 3, 4]
			]},
			{[
				this.modMatrix(
					[0, 2, 1],
					[1, 2, 1],
					[3, 4, 1],
					[3, 5, 1],
					[2, 2, feedback],
				),  [0, 1, 3]
			]},
			{[
				this.modMatrix(
					[0, 2, 1],
					[1, 2, 1],
					[3, 5, 1],
					[4, 5, 1],
					[2, 2, feedback],
				),  [0, 1, 3, 4]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 5, 1],
					[3, 5, 1],
					[4, 5, 1],
					[5, 5, feedback],
				),  [0, 2, 3, 4]
			]},
			{[
				this.modMatrix(
					[1, 2, 1],
					[3, 5, 1],
					[4, 5, 1],
					[5, 5, feedback],
				),  [0, 1, 3, 4]
			]},
			{[
				this.modMatrix(
					[2, 5, 1],
					[3, 5, 1],
					[4, 5, 1],
					[5, 5, feedback],
				),  [0, 1, 2, 3, 4]
			]},
			{[
				this.modMatrix(
					[3, 5, 1],
					[4, 5, 1],
					[5, 5, feedback],
				),  [0, 1, 2, 3, 4]
			]},
			{[
				this.modMatrix(
					[1, 2, 1],
					[3, 4, 1],
					[3, 5, 1],
					[5, 5, feedback],
				),  [0, 1, 3]
			]},
			{[
				this.modMatrix(
					[1, 2, 1],
					[3, 4, 1],
					[3, 5, 1],
					[2, 2, feedback],
				),  [0, 1, 3]
			]},
			{[
				this.modMatrix(
					[0, 1, 1],
					[2, 3, 1],
					[3, 4, 1],
					[4, 4, feedback],
				),  [0, 2, 5]
			]},
			{[
				this.modMatrix(
					[2, 3, 1],
					[4, 5, 1],
					[5, 5, feedback],
				),  [0, 1, 2, 4]
			]},
			{[
				this.modMatrix(
					[2, 3, 1],
					[3, 4, 1],
					[4, 4, feedback],
				),  [0, 1, 2, 5]
			]},
			{[
				this.modMatrix(
					[4, 5, 1],
					[5, 5, feedback],
				),  [0, 1, 2, 3, 4]
			]},
			{[
				this.modMatrix(
					[5, 5, feedback],
				),  [0, 1, 2, 3, 4, 5]
			]},
		].at(algo).value*[1/pi, 1]  //key is that it is divided by pi
	}

	*ar { | ctlMatrix, modMatrix, oversample=4, mul=1, add=0 |
		ctlMatrix = (ctlMatrix ?? { this.controlMatrix })
		.collect{|item|
			if(item[0].rate!='audio'){item[0] = K2A.ar(item[0])};
			if(item[2].rate!='audio'){item[2] = K2A.ar(item[2])};
			item
		}.flatten(1);
		modMatrix = (modMatrix ?? { this.modMatrix }).flatten(1)
		.collect{|item|
			if(item.rate!='audio'){item = K2A.ar(item)};
			item
		};
		^this.multiNewList(
			['audio']
			++ ctlMatrix
			++ modMatrix
			++ oversample
		).madd(mul,add)
	}

	*arAlgo { | algo=0, ctlMatrix, feedback=0.0, oversample=4 |
		var modMatrix, channels;
		#modMatrix, channels = this.algoSpec(algo, feedback);
		^this.ar(ctlMatrix, modMatrix, oversample).slice(channels)
	}

	init { | ... args |
		inputs = args;
		^this.initOutputs(this.class.numOperators, rate)
	}
	checkInputs {
		^this.checkValidInputs;
	}
}


SquareOS : UGen {
	*ar { |freq=440, phase=0, width = 0.5, oversample=1, mul = 1, add = 0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		if(width.rate!='audio'){width = K2A.ar(width)};
		^this.multiNew('audio', freq, phase, width, oversample).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

TriOS : UGen {
	*ar { |freq=440, phase=0, oversample=1, mul = 1, add = 0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		^this.multiNew('audio', freq, phase, oversample).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

VarSawOS : UGen {
	*ar { |freq=440, phase=0, width = 0.5, oversample=1, mul = 1, add = 0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(width.rate!='audio'){width = K2A.ar(width)};
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		^this.multiNew('audio', freq, phase, width, oversample).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

BuchlaFoldOS : UGen {
	*ar { |sig, amp = 1, oversample=1, mul = 1, add = 0|
		if(sig.rate!='audio'){sig = K2A.ar(sig)};
		if(amp.rate!='audio'){amp = K2A.ar(amp)};
		^this.multiNew('audio', sig, amp, oversample).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

SergeFoldOS : UGen {
	*ar { |sig, amp = 1, oversample=1, mul = 1, add = 0|
		if(sig.rate!='audio'){sig = K2A.ar(sig)};
		if(amp.rate!='audio'){amp = K2A.ar(amp)};
		^this.multiNew('audio', sig, amp, oversample).madd(mul, add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

SawBL : UGen {
	*ar { |freq=440, iphase=0, mul=1, add=0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		^this.multiNew('audio', freq, iphase).madd(mul,add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

SquareBL : UGen {
	*ar { |freq=440, phase=0, width=0.5, mul=1, add=0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(width.rate!='audio'){width = K2A.ar(width)};
		^this.multiNew('audio', freq, phase, width).madd(mul,add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

TriBL : UGen {
	*ar { |freq=440, phase=0, mul=1, add=0|
		var width = 0.5;
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(width.rate!='audio'){width = K2A.ar(width)};
		^this.multiNew('audio', freq, phase, width).madd(mul,add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

ImpulseBL : UGen {
	*ar { |freq=440, mul=1, add=0|
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		^this.multiNew('audio', freq).madd(mul,add);
	}

	checkInputs {
		/* TODO */
		^this.checkValidInputs;
	}
}

ShaperOS : PureUGen {
	*ar {
		arg buffer, in, oversample = 1, mul = 1.0, add = 0.0;
		if(in.rate!='audio'){in = K2A.ar(in)};
		^this.multiNew('audio', buffer, in, oversample).madd(mul, add)
	}
}

ShaperOS2 : PureUGen {
	*ar {
		arg buffer, input, buf_divs = 1, buf_loc, oversample = 1, mul = 1.0, add = 0.0;
		if(input.rate!='audio'){input = K2A.ar(input)};
		if(buf_loc.rate!='audio'){buf_loc = K2A.ar(buf_loc)};
		buffer.isNil.if {"Invalid buffer".throw};
		^this.multiNew('audio', buffer, input, buf_divs, buf_loc, oversample).madd(mul, add)
	}
}

OscOS : PureUGen {
	*ar {
		arg bufnum, phase, buf_divs = 1, buf_loc=0, oversample = 1, mul = 1.0, add = 0.0;
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		if(buf_loc.rate!='audio'){buf_loc = K2A.ar(buf_loc)};
		bufnum.isNil.if {"Invalid buffer".throw};
		^this.multiNew('audio', bufnum, phase, buf_divs, buf_loc, oversample).madd(mul, add)
	}
}

/*OscMOS : PureUGen {
	*ar {
		arg bufnum, phase, buf_divs = 1, buf_loc, oversample = 1, mul = 1.0, add = 0.0;
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		if(buf_loc.rate!='audio'){buf_loc = K2A.ar(buf_loc)};
		bufnum.isNil.if {"Invalid buffer".throw};
		^this.multiNew('audio', bufnum, phase, buf_divs, buf_loc, oversample).madd(mul, add)
	}
}*/

OscOS2 : PureUGen {
	*ar {
		arg sound_bufnum, phase_bufnum, freq, phase, buf_divs = 1, buf_loc=0, phase_buf_divs=1, phase_buf_loc=0, oversample = 1, mul = 1.0, add = 0.0;
		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		if(buf_loc.rate!='audio'){buf_loc = K2A.ar(buf_loc)};
		if(phase_buf_loc.rate!='audio'){phase_buf_loc = K2A.ar(phase_buf_loc)};
		^this.multiNew('audio', sound_bufnum, phase_bufnum, freq, phase, buf_divs, buf_loc, phase_buf_divs, phase_buf_loc, oversample).madd(mul, add)
	}
}

OscOS3 : PureUGen {

	*ar {
		arg sound_buf, phase_buf=(-1), freq=100, phase=0, sync_trig=0, buf_divs = 1, buf_loc=0, num_chans=1, chan_loc=0, phase_buf_divs=1, phase_buf_loc=0, oversample = 1, mul = 1.0, add = 0.0;
		var out;

		if(freq.rate!='audio'){freq = K2A.ar(freq)};
		if(phase.rate!='audio'){phase = K2A.ar(phase)};
		if(sync_trig.rate!='audio'){sync_trig = K2A.ar(sync_trig)};
		if(buf_loc.rate!='audio'){buf_loc = K2A.ar(buf_loc)};
		if(chan_loc.rate!='audio'){chan_loc = K2A.ar(chan_loc)};
		if(phase_buf_loc.rate!='audio'){phase_buf_loc = K2A.ar(phase_buf_loc)};

		//if(sound_buf.numFrames)

		^this.multiNew('audio', sound_buf, phase_buf, freq, phase, sync_trig, buf_divs, buf_loc, num_chans, chan_loc, phase_buf_divs, phase_buf_loc, oversample).madd(mul, add)
	}

	*fft_lp {arg fft_size, hiBin, filter_order;
		var temp, temp2;
		temp = (0..(fft_size/2));

		temp = temp.collect{|item| 1/(1+((item/(hiBin)**filter_order)))};

		temp2 = [0,0].addAll((1..(temp.size-2)).collect{|i|[temp[i],0]});

		^temp2.flat
	}

	*make_oscos3_mipmap {|server, path, fft_size=2048, filts_per_octave = 1, normalize_link_chans=false, action|
		var nrt_jam, nrt_server, sig_bufs, filt_bufs, out_file, in_file, sf, main_filt_buf, main_sig_buf;

		var file = SoundFile(Platform.defaultTempDir++"main_sig_buf.wav");

		var num_bufs = 11*filts_per_octave+1;

		var log = fft_size.log2;
		var full_filt = num_bufs.asInteger.collect{|i|
			var power = (log -(i*log/num_bufs).postln).postln;
			var high_bin = (2**power);
			OscOS3.fft_lp(fft_size,high_bin.round.asInteger.postln,512).asArray
		};

		var file2 = SoundFile();

		var signal_sf = SoundFile.openRead(path.absolutePath);

		postf("num_bufs: % \n", num_bufs);

		if(file2.openWrite(Platform.defaultTempDir++"main_filt_buf.wav", "WAV", "float", num_bufs, 44100)) {
			file2.writeData(full_filt.flat.as(Signal));
			file2.close;
		} {
			"Failed to open %".format(file2.path).warn;
		};

		out_file = Platform.defaultTempDir++"oscos3d_temp.wav";

		nrt_server = Server(("oscOS_nrt"++1000.rand).asSymbol,
			options: Server.local.options
			.numOutputBusChannels_(num_bufs)
			.numInputBusChannels_(num_bufs)
		);

		SynthDef("make_oscos3_buffer",{

			var chainC, chain = BufFFTTrigger(\sig_bufs.kr(0!num_bufs), 1, 0, 1);

			var demand = Dseries(0, fft_size);
			var pos = Demand.kr(chain[0], 0, demandUGens: demand);

			var sound, filt_chain = BufFFTTrigger(\filt_bufs.kr(0!num_bufs), 1, 0, 1);

			chain = BufFFT_BufCopy(chain, \main_sig_buf.kr(0), pos.poll, \main_sig_buf.kr);
			chain = BufFFT(chain, -1);

			filt_chain = BufFFT_BufCopy(filt_chain, \main_filt_buf.kr(), (0,fft_size..(fft_size*(num_bufs-1))).asInteger, 1);

			chain = PV_MagMul(chain, filt_chain);

			sound = BufIFFT(chain, -1);

			Out.ar(\out.kr(0), sound);

		}).load(nrt_server);

		main_filt_buf = Buffer.new(nrt_server, 0, 1);
		main_sig_buf = Buffer.new(nrt_server, 0, 1);

		sig_bufs = Array.fill(num_bufs, {Buffer.new(nrt_server, fft_size, 1)});

		filt_bufs = Array.fill(num_bufs, {Buffer.new(nrt_server, fft_size, 1)});

		nrt_jam = Score.new();

		nrt_jam.add([0.0, main_filt_buf.allocReadMsg(Platform.defaultTempDir++"main_filt_buf.wav", 0, -1)]);

		nrt_jam.add([0.0, main_sig_buf.allocReadMsg(path, 0, -1)]);

		num_bufs.do{|i|
			nrt_jam.add([0.0, sig_bufs[i].allocMsg]);
			nrt_jam.add([0.0, filt_bufs[i].allocMsg]);
		};

		nrt_jam.add([0.0, Synth.basicNew((\make_oscos3_buffer), nrt_server).newMsg(args: [\out, 0, \sig_bufs, sig_bufs.collect{|item| item.bufnum}, \filt_bufs, filt_bufs.collect{|item| item.bufnum}, \main_filt_buf, main_filt_buf.bufnum, \main_sig_buf, main_sig_buf.bufnum])]);

		nrt_jam.recordNRT(
			outputFilePath: out_file.standardizePath,
			sampleRate: 44100,
			headerFormat: "WAV",
			sampleFormat: "float",
			options: nrt_server.options,
			duration: signal_sf.numFrames/44100,
			action: {
				SoundFile.normalize(Platform.defaultTempDir++"oscos3d_temp.wav", Platform.defaultTempDir++"oscos3d_temp2.wav",numFrames:signal_sf.numFrames, linkChannels: normalize_link_chans);
				Buffer.read(server, Platform.defaultTempDir++"oscos3d_temp2.wav", action:{|buf| action.value(buf)});
				"done".postln;
			}
		);
	}
}