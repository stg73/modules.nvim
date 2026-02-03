local M = {}

local base = require("convert_base")
local tbl = require("tbl")

-- 参考にした記事: https://qiita.com/mikecat_mixc/items/8e3ca5f323cfda848220
function M.sha1(msg)
    local bytes = { string.byte(msg,1,-1) }

    -- パディング
    table.insert(bytes,0x80)
    local number_of_0 = 64 - (((#bytes + 8 - 1) % 64) + 1)
    vim.list_extend(bytes,tbl.map(function() return 0x00 end)(tbl.range(1)(number_of_0)))
    local msg_bit_len = string.len(msg) * 8
    vim.list_extend(bytes,base.align(8)(base.to(2 ^ 8)(msg_bit_len)))

    local H0 = 0x67452301
    local H1 = 0xEFCDAB89
    local H2 = 0x98BADCFE
    local H3 = 0x10325476
    local H4 = 0xC3D2E1F0

    local function S(n,x)
        return bit.bor(bit.lshift(x,n),bit.rshift(x,32 - n))
    end

    local function f(t,B,C,D)
        if 0 < t and t <= 20 then
            return bit.bor(bit.band(B,C),bit.band(bit.bnot(B),D))
        elseif 20 < t and t <= 40 then
            return bit.bxor(B,C,D)
        elseif 40 < t and t <= 60 then
            return bit.bor(bit.band(B,C),bit.band(B,D),bit.band(C,D))
        elseif 60 < t and t <= 80 then
            return bit.bxor(B,C,D)
        end
    end

    local function K(t)
        if 0 < t and t <= 20 then
            return 0x5A827999
        elseif 20 < t and t <= 40 then
            return 0x6ED9EBA1
        elseif 40 < t and t <= 60 then
            return 0x8F1BBCDC
        elseif 60 < t and t <= 80 then
            return 0xCA62C1D6
        end
    end

    local W = {}
    tbl.map(function(list)
        table.insert(W,base.from(2 ^ 8)(list))
    end)(tbl.chunks(4)(bytes))
    tbl.map(function(i)
        W[i] = S(1,bit.bxor(W[i - 3],W[i - 8],W[i - 14],W[i - 16]))
    end)(tbl.range(17)(80))

    local A = H0
    local B = H1
    local C = H2
    local D = H3
    local E = H4

    tbl.map(function(t)
        local TEMP = S(5,A) + f(t,B,C,D) + E + W[t] + K(t)
        E = D
        D = C
        C = S(30,B)
        B = A
        A = TEMP
    end)(tbl.range(1)(80))

    H0 = (H0 + A) % (2 ^ 32)
    H1 = (H1 + B) % (2 ^ 32)
    H2 = (H2 + C) % (2 ^ 32)
    H3 = (H3 + D) % (2 ^ 32)
    H4 = (H4 + E) % (2 ^ 32)

    return table.concat(tbl.map(function(H)
        local big_endian = base.to(2 ^ 8)(H)
        return table.concat(tbl.map(string.char)(big_endian))
    end)({ H0, H1, H2, H3, H4, }))
end

return M
