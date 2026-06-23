/*

* Copyright (c) 2026 Mikhail Abramov
*
* Author: Mikhail Abramov
* GitHub: https://github.com/MRTOkoN
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* ```
  https://www.apache.org/licenses/LICENSE-2.0
  ```
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.

*/



MGD = MGD or {}
MGD.Cardealer = MGD.Cardealer or {}
MGD.Cardealer.Money = MGD.Cardealer.Money or {}

local Money = MGD.Cardealer.Money

function Money.GetPlayerBySteamID64(steamid)
    steamid = tostring(steamid)
    for _, pl in ipairs(player.GetAll()) do
        if pl:SteamID64() == steamid then return pl end
    end
end

function Money.CanAfford(ply, amount)
    return IsValid(ply) and ply:canAfford(math.abs(tonumber(amount) or 0))
end

function Money.Take(ply, amount, reason, cb)
    cb = cb or function() end
    amount = math.abs(tonumber(amount) or 0)
    if !IsValid(ply) then return cb(false, 'Player unavailable.') end
    if !Money.CanAfford(ply, amount) then return cb(false, 'Insufficient funds.') end
    ply:addMoney(-amount)
    cb(true)
end

function Money.Give(ply, amount, reason, cb)
    cb = cb or function() end
    amount = math.abs(tonumber(amount) or 0)
    if !IsValid(ply) then return cb(false, 'Player unavailable.') end
    ply:addMoney(amount)
    cb(true)
end

function Money.UsedTransfer(buyer, sellerSteamID64, amount, reason, cb)
    cb = cb or function() end
    cb(false, 'Used dealer: money transfer is not configured. Override MGD.Cardealer.Money.UsedTransfer for the bank on your server.')
end
