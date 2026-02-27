local M = {}

local base = require("convert_base")
local tbl = require("tbl")

-- 参考にした記事: https://qiita.com/mikecat_mixc/items/8e3ca5f323cfda848220
function M.sha1(msg)
    local bytes = { string.byte(msg,1,-1) }

    -- パディング
    table.insert(bytes,0x80)
    local non_zero_bytes = #bytes + 8
    local current_mod = non_zero_bytes % 64
    if current_mod ~= 0 then
        local second_append = tbl.map(tbl.const(0x00))(tbl.range(1)(64 - current_mod))
        vim.list_extend(bytes,second_append)
    end
    local msg_bit_len = string.len(msg) * 8
    vim.list_extend(bytes,base.align(8)(base.to(2 ^ 8)(msg_bit_len)))

    local H = { 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0 }

    local function update_state(block)
        local A, B, C, D, E = unpack(H)

        local function S(n,x)
            return bit.bor(bit.lshift(x,n),bit.rshift(x,32 - n))
        end

        local function f(t,B,C,D)
            if t <= 20 then
                return bit.bor(bit.band(B,C),bit.band(bit.bnot(B),D))
            elseif t <= 40 then
                return bit.bxor(B,C,D)
            elseif t <= 60 then
                return bit.bor(bit.band(B,C),bit.band(B,D),bit.band(C,D))
            elseif t <= 80 then
                return bit.bxor(B,C,D)
            end
        end

        local function K(t)
            if t <= 20 then
                return 0x5A827999
            elseif t <= 40 then
                return 0x6ED9EBA1
            elseif t <= 60 then
                return 0x8F1BBCDC
            elseif t <= 80 then
                return 0xCA62C1D6
            end
        end

        local W = {}
        tbl.map(function(list)
            table.insert(W,base.from(2 ^ 8)(list))
        end)(tbl.chunks(4)(block))
        tbl.map(function(i)
            W[i] = S(1,bit.bxor(W[i - 3],W[i - 8],W[i - 14],W[i - 16]))
        end)(tbl.range(17)(80))

        tbl.map(function(t)
            local TEMP = S(5,A) + f(t,B,C,D) + E + W[t] + K(t)
            E = D
            D = C
            C = S(30,B)
            B = A
            A = TEMP
        end)(tbl.range(1)(80))

        H[1] = (H[1] + A) % (2 ^ 32)
        H[2] = (H[2] + B) % (2 ^ 32)
        H[3] = (H[3] + C) % (2 ^ 32)
        H[4] = (H[4] + D) % (2 ^ 32)
        H[5] = (H[5] + E) % (2 ^ 32)
    end

    tbl.map(update_state)(tbl.chunks(64)(bytes))

    return tbl.pipe {
        H,
        tbl.map(base.to(2 ^ 8)),
        tbl.flatten(),
        tbl.map(string.char),
        table.concat,
    }
end

return M
