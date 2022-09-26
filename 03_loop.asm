.def @ctr 0x100
.def @end 0x101
.org 0x0

ldimm '@'
strmem @ctr

ldimm 'Z'
strmem @end


loop_begin:
ldimm 1
addmem @ctr
strmem @ctr
write

submem @end
jmpeq end_loop
jmp loop_begin

end_loop:

terminate
