start
break *main +752
commands
 set $saved = *(long long*)($rsp+40)
 continue
end

break *main+818
commands
 set $rdx=$saved
 continue
end

run < input.txt
continue


