obj/main: src/main.adb src/particle.adb src/particle.ads
	gprbuild -XOS_Kind=linux -XBuild_Mode=fast particle.gpr
clean:
	gprclean -XOS_Kind=linux -XBuild_Mode=fast particle.gpr
