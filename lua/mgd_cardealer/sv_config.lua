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
MGD.Cardealer.Config = MGD.Cardealer.Config or {}

local Config = MGD.Cardealer.Config

Config.Economy = {
    SellBackPercent = 75,
    UsedListingFee  = 30,
    MaxUsedPrice    = 100000000,
}

Config.Cooldowns = {
    Buy     = 3,
    Used    = 5,
    GetList = 1,
    Spawn   = 3,
    Admin   = 3,
}

Config.Plate = {
    Letters = 3,
    Digits  = 4,
}

Config.UsedDealer = {
    Enabled = false,
    Pos     = Vector(0, 0, 0),
    Ang     = Angle(0, 0, 0),
    Model   = 'models/humans/group02/tale_07.mdl',
}
