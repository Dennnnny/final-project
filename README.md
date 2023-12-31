## Blockchain final project

主題： Gamefi  

核心 寵物養成遊戲  

主要相關合約會是： ERC721、ERC20

概念：  
1.最初會有一次的免費生成寵物   
2.在遊戲中提供一些任務：獲得代幣  
3.需使用代幣來升級寵物或買一些裝備：消耗代幣  
4.也可以用代幣再購買新的寵物（會有上限）：獲得新的NFT寵物  

---

12.21 log  

遊玩流程

初始進入專案： mint 一隻史萊姆  

解解任務：得到token + 道具nft

升級史萊姆： 使用token + 道具nft -> 把原本的史萊姆指向的地址改成新ㄉ

開始架構專案內容 + test cases 

Test cases:  

1. [x] 可以免費 mint 第一隻slime  
2. [x] 需要額外的 eth 來mint 後續的 slime 
3. [x] 一個地址一生只能 mint 三隻slime (like forever)
4. [] 一個人一次只能持有 3隻 slime 
5. [] ~~只有 admin 可以調整指向位置(?) ... 所以應該要透過一些方式???~~ 還沒想好ＸＤ
6. [] ~~測試把史萊姆交換給別人~~
7. [] 測試得到 道具nft 的功能
8. [] 測試升級 : 測試有把位置重新導向到新的地方 by 升級道具 + erc20 token

---

12.29 log

流程說明：
「解解任務：得到token」
=> 在得到道具的時候 會決定道具指向到的路徑： tokenURI
用一個 mapping 來存對應路徑的 metadata => 也紀錄這個道具可以升級的對應數字 uint256 => types 
?? 但會與哪個合約互動呢？ 直接去 mint erc20 + upgrade_nft in Slime(ERC721)?

「升級史萊姆： 使用token + 道具nft -> 把原本的史萊姆指向的地址改成新ㄉ」
function upgrade
=> input 是 _tokenId 要升級的史萊姆id , slimeTokenAmount 要使用的 erc20 數量, upgradeTokenId 升級道具
-> 檢查erc20數量足夠升級
-> 檢查tokenId 屬於 owner
=> burn 掉 erc20 & upgrade_nft , 讓現在這個 tokenId 的結構存成新的 道具tokenId 的 types

更新了 upgrade function 與 簡單先寫了 missionCompleted function 
更新了 slime 的 struct ， 多放了 tokenNeed & level 
目前 level 應該是還沒什麼特別用途， tokenNeed 則是用來記錄每次升級需要的 token 數量

這邊會思考一下 upgradeToken 的結構要怎麼設計
需要考量的點在於遊玩體驗 ˊ-ˋ 
要不要讓升級 與 道具之間 會有關聯 ... 
如果要有關聯，我就要做個機制：讓 user 不能重複使用同一個層級的升級道具來升級 
這樣就可以做到 升級道具 對應到的 升級後位置
如果沒有關聯：這樣 user 如果隨便 升級， 可能要處理更多的狀況
-> 傾向做一個 有關聯式的 升級流程

待完成
[] 指向圖的部分
[x] 升級道具的等級 （也許可以直接對應到等級 對應才給升級）

---

12.31 log 

[x] 升級道具的等級 （也許可以直接對應到等級 對應才給升級）
=> upgradeToken struct 也設立一個 level
[x] upgrade function test



新增待完成： 
[] 循環 -> 利用寵物之類的來得到token or 寶物 
=> 寫一個 goAdventure function + returnWithProfit function 
<!-- => 需要新增一組 mapping 對應 slimeToken 是否正在出去冒險 -> false 才能 goAdventrue -->
=> slimeToken 是否正在出去冒險 -> true 才有機會能 returnWithProfit ,（+ 時間限制！ 最少需要幾百個 block time 才可以招回）
<!-- => 需要新增一個 mapping 對應 slimeToken 出去的時間   -->
=> 應該可以改記錄在 struct 裡面： 一個 bool ableToAdventure + uint256 currentBlocktime
=> currentBlocktime 會紀錄 go adventure 當下的 blocktime 
  -> 然後在 returnWithProfit 的時候要檢查 block.timestamp - currentBlocktime > 100 之類的
啊 還需要在最後計算當次的冒險報酬！！ 會用 經過的時間 * 某個比例
=> 需要多一個 常數：獲利比例 ！！ 可能是 0.01% 之類的 
=> 多新增另一個 常數：最大報酬  變數：最大可獲得報酬 （ 這邊用一個常數 * 等級來計算 ）
