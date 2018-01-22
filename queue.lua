local push = function(list, item)
    item.p = list.head
    list.p = item
end

local pop = function(list)
    list.tail = list.tail.p
end

local iter = function(list)
    local current = list
    return function()
        current = current.p
        if current then 
            return current
        end
    end
end

return {
    push = push,
    iter = iter,
    pop  = pop
}
