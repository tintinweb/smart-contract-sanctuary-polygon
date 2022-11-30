// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title wrld cup wAIfus Contract
/// @author irreverent.eth

/*
                                    .............::^~~~~~~^::....            ........                                   
                                ..........   .^!YPGGGGGPPPP5YJ7~^.....            ......                                
                             ....:^~!!!77!::~YB#&#&#####BBGGPPPP5Y?!~::...            .....                             
                           ...^77?JJJJJJ?775B#BBGGGP555PPGGBBGGGPP555YJ7~^:..            .:..                           
                        ...:~??JY5GBBB5YYYPGP5YY5YYYYYYYYYYY555PPPPPP55YYJ7!^:..           .::..                        
                      ...^7??JPB###BBG5YY555YYYYYY5YYYYYYYYYYYYY5Y555PPP5J??!~~^:..          .:^:.                      
                    ...~7?7JPBBP55JJYJJJYYY5PGPPP555555555P5555YYYYYYYY5PP5J?7!^^:..           :~^:.                    
                  ...~??7?J55YJ???777?5GGP55PB####BGGGPGGPPPP5555YYYYJJJY5PP5J?!~^:...           ~~^::.                 
                .. :7?7777????7?777?P#&&#&#BGGPPGBB###BBBGPP55555YYYYJJJJJJY555J?!^::....         :!~^::.       ...     
 .....         . .!?777777??777777?G###BBBBGGPP555P5PGGBBBGP5YYYYYYJ????JJJ?JJJYJJ7!^::....        .7!~^::.        ..   
.........    .. :?7!?J?JJ?77?J???JP#BBGPPPPPPPPPP555YYJJY5P5YJJJJJJ??7777??7777777^:~~^:.......     .!7~^::..        .. 
    .........  ~?!!JYJ??7777YJ?JJYPBGGGPPP5555PPPP55YJ??77777777????7!!!!!!!!!~~~^^:.:~~^:.....:~^.   ~?!~^:::..       .
  .......... .!?!!JY?7!!!!7YYJJJY5PGPPPP5555555PPPYYJJ?77!!!!!!!77???7!~~~~~~~^^^^^^:..:~~^:..:!??J7~. ^?7!~^^::.     . 
........... .7?!!JJ??7!!!7JY5YJJ5PPP55YYJYYYYY5555YJJ??777!~~~~~~!!7777!~~^^^^^^^^^::::..:~~^^77777?JY7:~?7!~~^^^^:.   .
.......... .?J!~JYJ?7!!!!?~YPYY5PP55YJ??????JJYYJJJJ?777777!!~~~~~~~!!!!~~~~~^^^^^^^::::...:!JJ?77777??J?JJ7!~~~~^^^:.  
...........JY7~?YJJ7!!!7?^.PP5YPP55YJ??77777?77???J?7777!777!~~~^^^^~~~~~~~^^^^^^~^^^::::..  ^JY?7?77777?JJJ?7!!~~~~^~:.
.....:..:.YP5!7YYJJ777?YJ.:GPJ?P5YJ?7777!77!77!!????777777777!~~~~^^^^^~^~~~^^^:::~~~^^^^::::..~YYJ?777777???77!~~~~~~~~
...::.:^.JPPPJJYYJ??JY55?.^GY?755J?777!!!!!!!!!!!????777777??77!~~^^^^^^^~~~~~~~~^:^!7!~^^:::::..75YJ?77777777!!!!~!!~~~
..:^:^!.7G555PYYYJY55555!.!PJ7!Y5J?77!!!~~~~~~~~~!????777777?J?7!~~~^^^~~~~~!!!~~~~:.^?J7!~~^^^^^.^YPY??77777777!!!!!!!~
.^^^^7^^5YYPP5555555YY55!.?P?7~JYJ?7!!!~~~~~~~~~~~!?7??77777?YY?7!!~~~~~~~~!77777777!!~J5Y?!!!~~^~~:!P5J???7777!!!!!7!!!
^^^~7!.JYYPP55555YYYYYY57:5GJ7~?Y?77!!!~~~~~~~~~~~~~?7??77777?5J?777!!~!!!!7????77?77??J5P5YJ?7!!!!7~~5PYJ???777!!!!7777
^^~7?.7YJPGP555YYYJJJYYYJ?PGYJ7?Y?7!!!~~~~~~~~~~~~~~~?!??7777?YJYJ?7777!7777????J?????JJY5PP5YJ?7!!?Y?~YG5YJJ?777!7!!!77
^~!?^^YJPBPP555YYYYJJJYYYYYGPY??5J7!!!~~~~~~!~~~~~~~~~?~??777?Y~:JJ777777????JJJJJJJJJJYYY5P55YY?77J55Y7YP5JJ?77777!7!!!
!7!J:YJ5BGP555YYYYJJJJJJJJJPPYJ?5J?7!!!!!!!!!!!!~~~~~~~7~??77?Y~ .7Y?77777???JJYYYJYYYYYY5555YYYYJ?JYYYJ!?PYJ?77777777!!
!~?77YYBBGPP5Y5Y5YYJJ??JJJ?YG5J?P5J77!!!!7777!77!!~~~~~~7~7?7?Y^   ^JY?7!7777?J55YYYY5Y5555555YYYJJJJJJ??^!G5Y?777777777
:7?J5JPBGPP5YYY555YJJJJ????JGPY?PPY??7!!7777777?J7!!!~~~~7!!JJY:     ^JY?77777?J55YJ5P5555555YYYJJ???JJ?77:^P5YJ?77??7?7
~?7PB5BGPP5YYYY555YYJJJ?????GG5?YG5J?7!!7?????77?YJ7!!~!~~!7!JJ. ...::^?55YJJ???YP5JJ55YJJJY55YYJ?77?????77:^P5J???77777
?77P#BGP55YYYYYY5555YJJ?????5G5J?GPYJ?777JJJ??????5Y?7!!~~!!??J?!~~^^::.:~5PP55555PY??55JJ??Y55YYYJ?7?777777^~PYJ????777
?77P#BG555YYYJY55555YYJJ?????JPY75P5J??7!?YYJJJ????YYJ77777?????^          ^?????Y5PPJ?55J????JJ?JYYYJ?777777~!PYJ??7777
77?##GP55YJJJJY55YYPYYJJ???Y!:P5?JG5Y??7!!?Y5YJJ???7JJJ??PY?7!7??!.          :!7!!7?5PPYPPYJ??77777??Y5J?77777!~Y5J?7777
77Y#BGP5YYYJJJJYY??5YYJ?J??Y: ~PJ?PP5?7?7777J55YJJ??????7?PY?7777??:           .^!?77?PGPP5Y???77777??J55YJ?77?!:!5Y?777
77G#GPPYYYJJJJYYY??5YJJ???YY::.?PJYJPJ77??7777?Y5Y???7??77JY:~7?77?J7.            .^7?J5GGPYJ???77???JYYY555YY??7^:?PYJ?
7JGBGP5YYYJJYYY5Y??5YYJJJJ?::::.?55~J5?77?777!!7?YYJ??777775~  :!??7?J7:^~!!7~:..    .^75GBPYJ???7???JJYYYJJJYY5YJ7:^JP5
?Y!GP5YJJJJJJYY5J77YYJ?7??.      ?57.JY77J?77!!!!!?YJJ?7???YJ     :?PGB##&&&&&&#BPJ~:.  .^JGPYJ??777??JY5P5?77??J5GPY?PG
Y~:G5YJJJ???JYYYJ77JJ?77?~       .YY..7Y77Y?!!!!~!~!?JJ?????5:   :Y######G?!G&&BG#&&&B57^..~G5J??7777?JJY5GPYJJYPGGBGBGP
?..55YJJ????JJY5?!!??!777..       .5^  ~J7?5J!!~~~~~~!?J?77?Y?  !BGP#BPBG5~^PGBB?^~7YB&#B5~.JPJ?77777??J55Y7PGPPP5PP5555
:..Y5J????77JJY57!!!!!!7^          :~   :77J577!~~^~~~~7J????5^?P~ ~#GBGB#GPPPPGB:.. 5B7:.  :PY?77!!!7JJJY5^:JG5YYJJJJJJ
...?5J?77777?JY57~~~~!7!.   :7Y5YJ?!!^   .^7??^~77!~~~!^^7???J5?.  .BBPJYY~Y?^!YG^  !J.      J5?77!!!7JJJYY7..JG5JJJJJJ?
...!PJ777777?JY57~~~~!7. :?B&@&@&&&###G7.  :~7?:.:~!!!!~. .^7?J7.   ~P~^:......75. ^~        J5?77!!!7YYYJYJ:.:GP5YJJJJJ
...^PJ?77!!!7?J57~~~~!~~P&@&GJ####J^5&##Y:. ..^7!.  .^~~~^.  .^!~.   ^J:.   ..^J~ :.        ^5YYJ77777?5JJJY^.:GP55YYYJJ
....YY?777!!77J57~~!7JG&&&P^ :Y5B##BBGPPG!     ..^^.    ....    ...   .!^...:^7^ .         .5Y~J5J???7?Y.:!YJ:^GPPP5YYYY
:...7Y?77!!!!7?57~~!~5&&&?.  :&##BP5GG77JY.        ..                   .......           .JY^.:G5J????Y~  :?77BPPP55P55
^:..^5J7!!!!!!?Y?~!!?G#&G.    7#B5?^~~:.:!.                                              .??.   !B5JJJJJY?^..~YGGPPPP5P5
:^:..?Y?7!!!!!7JY!!?G5~!5Y:    !B5~.  ...:                                  ...         :?~      !B5YYYYYYY?^:~7PBGP555P
~^^:.:YJ7!!!!!7?Y77PPPY...^^:.  .?~:....:.                                            .^~.        ~GPYYY5YYY7:...!5GGP55
:~^^:.~5J7!!!!!7JYPPPPG5:....:::..^~^:..                                             ..            :5G5YYYYYYY~.   :75GG
..^!~^:!5J7!!!!7?JGPP5PGP^...........                                                              .:7BPYYYYYY5?^.    .~
...:~77!JPY?!!!77?PP5P5PGG^...........                                                           :!:..^GB5YYYJY5J7~.    
......:~!YGY?77777YG55555GP^..........                                                          ~##J^..:YBGYYYYY5Y?!^:. 
..........7G5?7777?GG55Y55GP:.........                                                         7&&&&&P!..~GBPYYYY5YJ?!^:
.......... ~GPJ?77?YGP555Y5B5..........                       .........                       [email protected]&&&&&&&#Y^^YGP5YJJY55Y?!
...........75PPY?777YPP5YYYYBY.......                  .:^!7?7!~~^^^^^^:                    [email protected]&######&&&&BJYGP5YJJJJ5P5
..........~5JJYP5?777J55YYYYYGJ.....               .^?Y5P5Y7~^::::::::::                  .:^[email protected]&##########&&###GP5J???JY
.........:5J??77J5J777?5YYYYYYGJ...                7GP5Y?~^:::::::::::^                 .:::~&&######BBBBGBBBBB#BP5YJ?77
 .. .....JY?7?7!!7?JJ?7J55YYYYYP5:                 .JPJ~^^^::::::::::^.                .::..7&&####BBBGGGGPPPPPPPPPP5YJ7
        ~Y?J?77!~!!!!?JJY5YYYYYJ5G7.                 ^!^^::::::::::::.               .::....P#&&###BBGGGPPP5P5555555YYYY
       .?7!J?77!^!7~~~!?Y5YJJJJYJYGP~.                 .::::::::::..              .:::......BBG#&&##BBGGPPP5555Y5555YYYY
       ^7~~!J7!~^:7~^^^~?55YJJJJJJY5G57:.                 ......                .::......  :#G5YG&&##BBBGPGP5555555Y55YY
       !!~^^?7!7:.~~^^^^^7555YJJJJJJJYPPY7:.                                  .^:.......   :BPJJ?YB&&#BBGGGGP555555?!755
      .!~^::~?!!...~^:::::~Y5???JJJJJJJJY555?~:.                           .:^^.......     .GGYJ???JJ#&#BGGPP5555555Y~:!
      .7^::::?7!....^::::::^??!!!7?JJJJ???JJYY5Y7~..                    .:^^:........       5G5YJ???.:Y###BGG55555YYY5Y7
      .7~::::~?!. . .::::::::~7!!!!7?JJJJ???????JYJ?!^.               .^~^:.........        7GYYY??J^  .7G#BGP55YYYYYYY5
       ^7^::::!?:     .:::::::~!!!7!!7??JJ???77777777?7!~:.        .^~~^..........          :PYJJJ??!... .^?PGP55YYYYJYY
..     .77^^:::7~       .::::^^^!!?J!!!77?J??777!!!!~~~~!5Y7^...:~!~^:...........            7577YY??:      .^7YPP5YYJJY
GBG5?!^.:7?~^^^~7:    .  ..:^^:^~~~77::~!!7?77!!!!~~~~~~~JYJYJ?7!~::...........               !J!~7JYJ:        ..~?Y555Y
&&&&&&&#GPG57~~^~7~^::....  .:^~^~~~7!....:~7777!~~~~~~~~JJ!~~^^:::...........                 ^?!~~~!?~:.        ...^7J
7?JPGB#####BGJ!~~!JYYY55YJ?!^::^!!!!!7!.......:^~!7!!~~!~JJ~^::::...........                    .?Y?!~^~~^::........   .
.....:^~7J5PPG5?~~!?YJYJJY55555J??JJJYY?~:.:^~?YGB###GJ77J?^^:::...........                   .~J5YJ777!~^^^^:::..      
............::^?J!~~JYYYYYYYY5YYYYYJY5PBBBB#&@@@&&&&&&#J?J!^::............                .:!JPP5J?7777!77!^:...        
................^77~^^::...:^~!77??JYG#&@@@@@@&&&&&&&&5?7~^::::...........             :!YPGGG5YYYJ?J?777777!!~^:...    
..................^!!^:.......  .^5B#BP5P#@@@&&&&&&&#Y!~^::::............          .^?PBBBBGPPPGPGGGGPP5YYJ~:..:^^~~^:..
....................:~~^:.....:!5GGY?!~~~7#@@&&&&&&B?^::::..................   .:75B#BBBGGGBBBG57~^~7J5GGGPP5J!~:...:^~~
......................:^^^^^^~7?!~^^^^^^^~&@@&&&&&#7::.......................~JG##BBBGGGBBBGJ!:...     .:~?Y5PPPYJ?!^:.:
......:..................:::::::::::^^:^^[email protected]@&&&&&&7::....................^75B##BBBBBBB#BP?^:.....            .^7Y5P5Y?!^
:::..:::........................::::::^:~&@@&&&&&J:..................:!YB###BBBGB###B57^.......                 ..:~?YYJ
.:..:^^:::......................::::::::[email protected]@@&&&&5^...............:~?G#&&#BBBBB##BPJ!:..........                ..    .^7
....^~^:::.....................:::::::::[email protected]@&&&&#~:............~?P#&&&##BB####GY7^:............               ..         
...:!~^::::...................:::::::::!&@&&&&&5:.........^75B&&&&#######BP?~:.............                 ..          
...~!^^:::....................:::...:::[email protected]&&&&&&7:.....:75B&&&&#######BP?!^:................                ..           
..^~^^::::...................:::....::^[email protected]&&&&&B~:::~?G&&&&#####&&&BP?^:.............   ..                 ..            
.^~^:::::............................:7&&&###&B7?P#&&&######&&&BY7^:...................                  ..             
^^:::::..............................:B&#BBBB&&&&&#####&&&#BP7^:................. .                      .              
^::::::........::...................:5&#BBGB#####B####BP?^................  .  ..                       ..              
:::::.:.....:::.:..................:5#BGPPGBBBB###BPJ!:..............      ..                          ...              
::........::::::..................~GBGGGGGBB###B57^.......... ..  .                                    ...              
....:::^7!:::::::::..............^##BGGB####GJ~:........   .                                           :..              
...:^!P#@Y::::::::...............:?PB####P?~........        ..                                        ::...             
:[email protected]&&~:::::::::::.............:::^~^:...............                                             .^.....            
P&&&5#&@G         ............                                                                       ^:..........       
YGGB!G##~                                                  ...                                      .~:..............   
~!~^...                                                  .^:~77!^:...                               ~^:...............  

*/

import "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

contract WrldCupWaifuContract is ERC1155, DefaultOperatorFilterer, Ownable {
    struct Token {
        string name;
        uint256 totalSupply;
        string uri;
    }

    uint256 public numberOfTokens;
    mapping(uint256 => Token) public tokens;
    mapping(bytes32 => bool) public tidUsed;
    mapping(bytes32 => bool) public claimed;

    constructor() payable ERC1155("") {
    }

    modifier tidCheck(bytes32 tid) {
        require (tidUsed[tid] == false, "Already minted: tid");
        _;
    }

/*
...........        YB: ~G!^^^^^^~~~!7??J555GBBGGGPPGBGGPPGPPP55Y555YY5Y?JJJJ5GBBBBBB########&#&&&&&&&&&&&&&&&&&&&&######
.........        .PB#~ !G7!~~~~~!!!777??JJPGBBBBBBBBBBBBBBBBBBBBBBBBBBBGPPP5PGGB##BB#####&&&&&&&&&&&&&&&&&&&&&&&&&&&&###
.......         ^B###5 !#5?77?7???JYJ55Y5PPPBBBBBBBBBB#BBBBBBB####7^^JPGBBGGGGGGB######&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
.:...          ~######^^#GP5YYJYPPGBBBBGGGGGBBBB############57!5##PY?Y^:7JGBGGGGGGB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
:..           ^######&P:G#BBBGGGGBBBGP##BBBBBBBB##############G7?&&&&&#BP7!5BBBBGGGB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
..        .   P#######&!5#####B#####B^.?####BB##################B&&&&&&&&&&###BGGGGBB#&&&&@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&
.       .:   :&#######&BP&###########&7 .G&&#######&&&&&&#&&##&&&&&&&&&&&&&&&&##BBGGBBB&&@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&
      .^^:.. ?&#######&&&&&&&#######&&&B?7!J&&&&&&&&&&&&&&&&&&&&&&#&&&&&&&&&&&&#########&&@@@@@@@&&@&&&&&&&&&&&&&&&&&&&&
     :~^^:   P&&######&&&&&&&&&&&&&&&&&&&&G~.?&&&&&&&&&@@&&&&&&&&&&&&&&&&&@@@&&&&&&####&&&&@@@@@@@@@@&&&&&&&&&&&&&&&&&&&
    ~~^:^:7JP&&&&&###&&&&&@&&&&&&&&&&&&&&&&@#!^[email protected]&&&&&&@@@@@&&&&&&&&&&&&&@@@@@@@&&&&&&&&&&&&&@@@@@@@@@@@&&&&&&&&&&&&&&&&
  .7!~~~^5###@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#?J&@@@@@@@@@@@@&&&&&&&&&&&&@@@@@@&@@&&&&&&&&&&&&@@@@@@@@@@&&&&&&&&&&&&&&&
 :?!!!~~P####@&&&&&&&&&&@&@@@&&&&&&&&&&&&&&&&&&&##@@@@@@@@@@@@@@&&&&&&&&&&@@@@@&.:J&@&&&&&&&&&&&&@@@@@&&&&&&&&&&&&&&&&&&
!YJ7~~^J#####@&&&&&&&&&&@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@&&&&&&&@@@@@@B. .!#@@&&&&&&&&&&&@@@@@@@@@@&@&&&&&&&&&
Y?7~~^!#####&@@&&&&&&&&&@@@@@@&&&&&&@@@@@&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@?   [email protected]@@&&&&&&&&&&@@@@@@@@@@@@@&&&&@@
7!~!~^5#####&@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y.  ^P&@@&&&&&&&&&&@@@@@@@@@@@@@@&@@
GJ~~!~G####&#&@@&&&&&&&&&@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B7. .J&@@&&&&&&&&&&&@@@@@@@@&&@@@@
#BPJJY####&@[email protected]@@&&&&&&&&&@@@@@@@@@@@@@G.^J#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B7..7#@@@&&&&&&&&&&@@@@@@@@@@&@
#######&##&# :@@@@&&&&&&&&&@@@@@@@@@@@@@5. [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P??5#&@@@@&&&&&&&&@@@@@@@@@
BB####&##&&~ .&@@@@@&&&&&&&&@@@@@@@@@@@@@B.   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPP#&@@@@@@@@@@@@@@@@@@
BBBB##&#&&G   [email protected]@@@@@@&&&&&&&@@@@@@@@@@@@&&7     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@
######&&&&J . [email protected]@#@@@@@&&&&&&@@@@@@@@@@@@#^YP~      :7#@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@
#####&&&&&7   .#&P?&@@@@@@@&&&&@@@@@@@@@@@P :?J~.      :J&@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
&####&&&&&7    ~P.:.#@@@@&&@@&&&@@@@@@@@@&@?  .^!~.       ^J&@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
&&&&#&&&##!     ^    [email protected]@@@@&&&&&&&@@@@@@@@@&:    .::.        :J#@@@@@@@@@@@@@@@@@@@@&&@@&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@
&&&&&&&&##?           [email protected]@@@@@@&@@&&@@@@@@@&@#.                  [email protected]@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@
&&&&&&&&#G5.           [email protected]@@@@@@@@@@&@@@@@@&&&B                 .~JY5YB&@@@@@@@&#&@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@
&&&&&&&@###!            :#@@@@@@@@&@@&@@@@@&&&B.            .~Y57.     .~?P#&@@@&##&&@@@@&&@@&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&@@Y##:^!!7~:.      ~#@@&@@@@@@&&@@@@@&&&#:         ~JY!.             :~YPJYY5PG&@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@
&&&&&&&&@!7&?   ..^!?!~:.   ?&&&&[email protected]@@@@@@@@@@&&&?     .7Y!.    ..:!?PGB##&&&G?^.    ..:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@&&&&&&@&.5&^     ..:^::^:. .?#&&P7J#@@@@@#P#&&&&B^  !7:    .!YB&@@@@@@@@@@@@@@&P?^     :&@@&@@@@@@@@@@@@@@@@@@@@@@@@@@
:[email protected]&&&&&&@P P&:  ?#@@@@&BP?^.   ^5&&?..!5#@@#?7P&&&&G~.    :5#&#&@@@@@@@J.^!?5B&@@@@B?.. ^&&#::^~?P#@@@&BGYJY5P#@@@@@@@@
  7&@&&&&&@G.J&!^#@@@@@@@@@@@#5^  .?#G~   .~5GJ::~YG&&B?: 7BG#@@@@@@@@&@B      .:7&@@#J:.~&&!      :5!:::..::::[email protected]@@@@@@
   .7#@&&&&@#^~#@@@@[email protected]@@@@@@@#!   ^7?~.     ..   .:[email protected]@@@##BPPY?7         &&~.   .PG       ..    ..^^^^^.#@@@@@@
 ... .~G&@&@@@GP&@@@5: [email protected]@@@@G#@@Y    .^~~:.            .::P#@@#P&&GGG&J        ?J       !~           ..::^^~~^[email protected]@@@@@
   ....^[email protected]@@@@@@@&5G#G:  [email protected]@&&&@@@@J      .:^^:             ..G#J!?BG?7P~       ::        ^          .7J7^~~^^~^:@@@@@@@
     .!#@@@&&&@@@@@Y:.:   !&[email protected]@@@.          .               ::....:^7       .          .          !?77^::^^.^#@@@@@@@
   [email protected]@&&&&&&&&&&&@#!...  .7!~^~?7Y.                            ....::                             ^???!:::::[email protected]@@@@@@@@
 :J&@&&&&&&&&&&&&&@@@@G:.     .....^                                                               ^!^^:..:~Y&@@@@@@@@@@
P&@@&&&&&&&&&&&&&&@@&&&#7       ..:.                                                               .....~Y&@@@@@@@@@@&&&
@&&&&&&&&&&&&&@@@@@&#GG5B?                                                                        ...~5&@@@@@@@@&&&&&&&&
&&&&&&&&&&&@@@@@@@&#PJJJ?Y7                                                                      .:7#@@@@@@@@@@&&&&&&&&&
&&&&&&&&&@@[email protected]@&&GYJJ?77!J:                                                             .7GBBP5YG&@@@@@@@@@@@@&&&&&&&&&
&&&&&&&&#[email protected]&BPYJ??7!!!~7                                                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@&&&
&&&&&G?^:[email protected]&&G5YJ777!!~~^~~                                                           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#
&#57:..:7B&&&#5JJ77777!~^~~^!7                                                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&
5^..::[email protected]@&BPYJ??7!!!!7!~~^~^7J.                                                     .:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
::::[email protected]@&BYJJ?7??7!7!~^^~~~~~^~?~.                           .                     .~????&@@@@@@@@@@@@@@@@@@@@@@@&BB&@@@
^.:[email protected]&#GJ?777!7777~::::^!~~~~^^!7^.              .5Y55JJYJ?JY5:                 [email protected]@PP&@@@@@@@@@@@@@@@@@@@@G~!JB
::.7&&#5?777!~!777^:::::~!!~~~^^^^~7~.             ?BBGPYJJJJ?Y:               :7?7~~~^[email protected]!?P&@@@@@@@@@@@@@@@@@@#~^:
::~B#G5?!7!~!!~!~::::::.^J!~^~^^^^^:^^^:            .JPY??7??7:             .!Y5?!~~^^^^^~~G&J^:::~?5B#@@@@@@@@@@@@@@#^!
:^5Y?77!!!!~~!!^:..:.....!7!~~^^^^^^^^^.:..            :^~^:.             ^J5J7~~~^^^^^^^^~~JB5!:..:..::^!?P#&@@@@@@@@G~
!J?7!~~~~~~!!^:.::.......:^!77~~~^^^^^^   .....                        ^JP5?!~~~^^^^^^^^^^^^^!Y5Y!^:..:.:::^^[email protected]@@@@@@@B.
Y??!~^^^~^!!:::.:::.........:^?Y7~~~~^!:      ....                  ^YBGY7!~~~^^^^^^^^^^^^^^^^~~7YY7~^:::::^^[email protected]@@@@@@@@B
?!~~~^^^~!~:::..:........:..:.:~YY?7!!!7~^:::^^::^~^:.           ^Y#&GJ7!~~^^^^^^^^^^^^^^^^^^^^^^[email protected]@@@@@@@@@@
!~~~^^^^~~::::........:.......::!YJ??!7!!!!!~!!~~!~~~!~:.     :5#&&BY7!!~~^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@@@@@@@@@@
^^^^^^^~~:::::............:.....::[email protected]@&BPY7!!~^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~!7J&@@@@@@BYJ??5
~^^^^~~~^::::..........::.....:....:^~!!7!~!~~^~^^^^::^~~!!!~#@&PJ?7!~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~!7#@@@@@@57!7!!!
^^^^^~~~::.................::.:::...............::::^^~~~~~~:B&BJ?!!!~~~~~^^^^^^^^^^^^^^^:^^^^^^^^^^^[email protected]@@@@@@&#B#GPP
^^^~!7!:..................:::.......::::::^^^~~~^^^^:^^^^^^^^#&G?7!~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^~~?#@@@@@@@@@@@@@@@
^!~!7~:.:::......::...:.....:::::::^::::::::....::^^~!?PPBBG5&@G?7!!~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@@@@@@@@@@@@@@@
~!77^.:::.::::::...:::::::::::^^:....       .:~7G#&@@@@@@@@@@&@#Y77!!~~~^^~^^^^^^^^^^^^^^^^^^^^^^^^7G&&&&@@&#B#&&@@@@@@@
77!:...:::::....:::::::.:::::..    .     .!5#@@@@@@@@@@@@@@@@&@BJ777!~~~~~~~~^^~^^^^^^^^^^^^^^^^^7P&&PYYJJJ???77?JJ5PP5J
!7^.:::::.:::.::::..:::^^^:....:7P#&BGGGB&@@@@@@@@@@@@@@@@@@GG&#J77!!!!!~~~~~~~~~^~^^^^~~~~~^^^!P##PJJJJ???777!7!~~~!~~!
~:....:..::..:::.:::::~~^..:!Y#@@@&@@@@@@@@@@@@@@@@@@@@&@@@P7Y&&Y7777!!!!~~~~~~~~~~~~~~~~~~~~?P##5YY?Y55JJ7!7!!~~!!~~~~!
:..........::.:::::::~:..:G&@@@@@@@@@@@@@@@@@@@@@@@&GG5JY5J777&&Y7777!!!77!!!!!~~~!~~!~~~~75B&&GJ??J55YY77!!!!!~~~~~~~~~
.....:.:::::::::::::~::.:[email protected]@@@&&&&&&&&&&&@@@@@@@@@#5JJJ????77!P&5?777777777!77!!!!!!!!!!?P&&#5JJJYYY5Y??7!!!!~~~~~!~~~!!
:::..::..::::::::::^!^:^#@&&&#########&@@@@@@@&@@#YJ?7?7777!!!J&G?777777777?77777777?JP###5J???J5&GJJ777!!~!~~~~~~~~!~~!
.::::::^^^^::::::::^~::[email protected]&###########&@@@@@@&&@@#YJ?77?777??77!Y#PJ?777777777777?YP#&#GJ?77!7?Y#@B5J?77!!!!~~~~~~!~!!!!!
YPGB#GY7^:.........:~:[email protected]&&#########&@@@@@@@&&@@#5YJ?777777JJ?777JGBBP5YYJYYY55P####[email protected]&PYJ?77!!!~~~~~~~~~~~~~!!
&&&&&J:............:!!&&&########&&@@@@@@&&&@@#5YJJ??7777??JJYJ?77?5BBGBBPPGPPP5YJ7777777?YG&@&GYJ?77!!!!!!!~~!!!!!~~!!!
&&#Y^[email protected]&&&#####&&[email protected]@&&&&&&@@#P5YJ?J??????JYY5J??77!!!!?!~!7!7?7!7!777?5#@@@@&GYJ?777!!!!!!!!!!!!!!!!!!!
Y~.  ....... .......!&&&#####&&5!?&&&&&&&&@&#BP5YYJJ???7?JJY555Y5J77!7!!77!~!7JPG5GG#&@@@@@@@&GY?77!!!!!!!!!!!!!!!!!!!!!
 ...................:&&&####&G~7B&&&##&&&@@&&BPYYYJJ?????J??JYY555B&B5JJJY5G#&@@@@@@@@@@@@@@@BPY?777!~!!!!!!!~!!!!!!!!!!
*/
    // Token configuration

    function setNewToken(string memory tokenName, string memory tokenURI) external onlyOwner {
        require(bytes(tokenName).length > 0, "Missing name");
        require(bytes(tokenURI).length > 0, "Missing URI");
        Token memory token = Token({
            name: tokenName,
            totalSupply: 0,
            uri: tokenURI
        });

        tokens[numberOfTokens] = token;
        ++numberOfTokens;
    }

    function setURI(uint256 tokenID, string memory tokenURI) external onlyOwner {
        require(tokenID < numberOfTokens, "Invalid ID");
        require(bytes(tokenURI).length > 0, "Missing URI");

        Token storage token = tokens[tokenID];
        token.uri = tokenURI;
        emit URI(tokenURI, tokenID);
    }

/*
                          ...    ....:^~!!!~~!?JY5GGPY7Y#GPGGG&@P7?##BBBBGG5J7^.                                        
                     .....    .:^~!!7!77!!7JYPBGGGGGGGGGGPPPYY5###BBBGGGGGGGPGP5?~:                                     
                   .....:^~!7777777777!?JYPPPPPGGGGGPPGPGPPPPPG#BGGGGGPPPPPPPPPPPPYJ~.                                  
           .     .:^~!!7???7777!!!77!?5PPPPPPPPG#######BBBGGPPB#BBBBGGGGPPPPPPPPPPGGG5?^.                               
   ....:::.  .:~!77777777?????7!7!!7JPPPPPPPPPGGBB###&#&&&@&###BBBBBBGGPPGPGPGGGGGGGGGGGY~.                             
.........:^[email protected]@@&&###BB#BGGGGGPGGGGGGBBGBBBBBB5~.                           
::^^~~??J5PGGGGGGGGBBBBG!::!555PPPPPP55YYYYGGGPPPGPGBBB&@&&######BBGGGGGPPGGGGBGGBBBBBBBBB##Y^                          
77777777YPPPPGBBBBBBBBBBBGGGGGG5YJ?JJJY55PGGGGGPPPPPB&@@@&&&#####GGGGGGGGGGGGBBBBBBBB##B##BB##Y:.                       
777!777?YPPB#####BBBBB#####GY7^^7Y5PPPPPPGGGGGGGGGGGPGB&@@@&########BGGGGBBGGGBBB####B##B#BBB##G: .                     
Y5YY55YPG#&&&##BBBB##&&&#Y77::?5PP5PPPPPGBBB###&&&&&&###&@@@@@#&#####YGBBBGGGGGBBBBBBB####BBBB##B~ .                    
YY5YYPB&@&&&#####&&@@@B?:!JY5PP5555P5PPBBBBGGGBBB#BBB###&&@@@@@&&###&##BBGGGBBBBBGGBBB######B###&&Y..                   
PPGGB#@@@&&&###&@@@@#7 .J5JY55P5555555PPPPGGBBBBBBBGGGGGGBB#&&@&####B#BGBBB###BBBBBBBB##########&@@B^:.                 
#&&@@@@@&&&&&&@@@@@Y. .5P5JY555555P5PGGGBGGGP5YY5GGGGGGGBBBBGGB#&#BBBBBBBBGPGB#################&&@@@#~:                 
@@@@@@&&&&&&@@@@@#P5: Y5YYYY5P5PPPPPP55Y55Y5YJJ??YGGG5PP5PPYYYJJ5PGPGBBBBG7?!G&#############&&&@@@@@@&~^                
@@@@&&&&&#&&@@@#5PBB7?5YYY55555YYJJJJYJJYY5PPYY55PP5555YYYYYYYJ?J??Y~7B#B?!G#&###&&&##&&##&&@@@@@@@@@@B^^               
@@@@&&&&&#&&&@P!G#BP5P5Y5YJ?7?JJJJYJJ555P55Y5YY555PPPPP5YYYP555JJJJY ?##BGB#B###BBB#@@&&&&&@@@@@@@@@@@@J!:              
@@@@@@&&##&&@@G7&#&###B5??J55PP5YY55YYYJJYYYYJY5PPP5J7!7?JYYY?77?JY~~#&#BGGGGGGGBBB&@@@@@@@@@@@@@@@@@@@B:7              
#[email protected]@@@@@@@@@&@@@&##BGGBGGPPP55YJ??7??JJJY5PPPY7^^~?JYYYJ!^!~!?JJ:PB##BB###&&&&&@@@@@@@@@@@@@@@@@@@@@@~?^             
?YG#@@@@@@@@@@@@&&&##&@@#GPPP5JJ?77777!?Y5PP5J!~^:~JY55555?~~77~^~:JG?7P#@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@Y?7             
@@@@#B&@@@@@@@&&&&&&&@@BGGPP7. ^~!!!~!!?J5J!~!?YPPPPPPP5555J7??7?J?PY:..:~7JPB#&@@@@@@@@@@@@@@@@@@@@@@@@BJ5             
PJ!^.?&@@@@@@&&&&@@&&@BGGGG!      ...:::77!J5GGGGGGPP55555PGPJJJJ5PP7...... ...:^~~~J&@@@@@@@@@@@@@@@@@@@@#:            
  .:[email protected]@@@@@@@@@@@@&#&&GGGGP5J77~!~~~~~~7J5GGGBBGPPP55P55PPPPPPPP5G55:.... .          :Y#@@@@@@@@@@@@@@@@@@&~            
 ~^[email protected]@@@@@@@@@@@##BB##GGGGGPPP555555555PGGBBGPPPPPPPPPPGGPPPPPPPGPP7..                 .~?&@@@@@@@@@@@@@@&5?            
[email protected]@@@@@@@@@&##BBGGGBGBBBBBBBBBBBGPPPGBBBGPPPPPPGPGGGBBGPPPPPPGG55:  .                   [email protected]@@@@@@@@@@@@@J~Y            
 [email protected]@@@@@@@&&#BBBGGBGGBBBBBGGGGGGGGGGGB##BGGGPPPGBGGGGBBGGPPPPPPGPP~                        ^[email protected]@@@@@@@@@@&.!J            
[email protected]@@@@@@&&&#BBBBBBBBBBBGGGGGGGGGGGB###BGGGGGPGGBBBBBB#BGPPPPPPGPP7 .                        [email protected]@@@@#[email protected]@#^BBP5J?7?77?JPG
@@@@@@&&###B##&&&###BBBBGGGGGGGGBB###BGGGGGPGBBBBGGB#BBGPPPPPGGP?.                            [email protected]@@@#G&@@#[email protected]@@@@@@@@&&&##
@@@@&&######&&&&#BBBBBBBGGGGGBBB#&&#BGGGGPGB#BBGGB#&#BBGGPPPGBGJ.             .:^~~~~^^^:..    ~#@@@@@@@&@@@&&#######BBB
@@@@&&####&@@&#BBBBBBGBBBBBB####&#BGGGGGPG##BBGGB##&#BGPBGPPBB?.         .:!?555J7~^::......... [email protected]@@@@@@@@@&&&#B#BBBBBB
@@@&#&&&@@@@&BBBBBBBBBB###&###&&BBBGGGGG#&#BBGGB#75&BGPPBGPBB7.       .~YBBPJ!:.                :[email protected]@@@@@@@@@@@&&&###BBBB
&&&&&@@@@@##BBBBBBBBB###&&###&#####BBBB&&#BBBB#P~.5&BGPG#GGB7...    .?B#P7^.      ...     ..... :#@@@@@@@@@@@&&&@&&&&#BB
&&&@@@@&##BBBBBBBBB###&&#B###BGGBBBB#&@&&&###G7...5&GGPBBGB?...   .!P5!:.  ..:~!!!!!~^^^^:[email protected]@@@@@@@@@@&&&&&&&##BB
&@@@@@&##BBBBBBBBB##&&#BB#BGGGGGGGG#&#BBBB#GP?:.. Y#GPG#BBY:...   .^.  ...^?YYY5PGB##&&@P7^:.....~#BPBG#@@@@@&&&&###BBBB
@@@@&&####BBBBBBBB#&#BBBBGGGGGGGG#&#BBBBGY!^::^::.P#GB#BBJ:...  ... ....~JPG#&@@@@@###&@@@&[email protected]@@@@&&##BBBBGG
@@&&####BBBBBBBB#&#BBBGGGGGBBB####BGGPY7^........:BBBGYBJ...    ......:JG#@@@@@@@@#7.:~~?5&@@P?!^^YGGGPYY&@@@@&&###BBBBB
&&##########B#&&#BGGGGGBB###@@@@&&&&&#GG5Y7!~:...!##5!G?....   ......^Y5&@@@@@@@&7?P!     [email protected]?^:::[email protected]@@@&&##BBBBB#
#&&###&&&@&&&#BGGGGGBBBP5PB&@@@#B&@@@@@@@@#GJ!^..5B7.J!...   [email protected]@@@@#&&G    :G!:::[email protected]@@@&&###BBBB#
&&&&@@@@@@@@@#BGGGBBPYJYP#@@B?^.~&@@@@@@@&B##Y:.^Y^ :^          ... .^^ Y5?5GYB&YJYY5   .~^.::.?GPP555JJ7#@@@@&&&##BBBBB
@@@@@@@@@@@&#BBBBBBB55G&@@@Y.   ~###&&&&&@#P??^...  .                   ^#&7::^7!~~?~  .::::..^[email protected]@@&&@@&@&#BBBB
@@@@@@@@@@@###BPYYPGP77JP&#.     ?!~G&&@&&&#&Y.                          :?^  ...:~~ ..::.:::[email protected]@&#B#&#YG&&#BB
@@@@@@@@@@@@#PY?77J5GP!^~!Y!     [email protected]&PY?PY~~~?Y.                         ...:::^:^~~:^:::::::::[email protected]@&#BGGB#5 ^JG##
@@&@@@@@@@@@&5?777!J55P!:::::.    7#5^^.....~:                         ....:::^^^^^:^:^^:^:::[email protected]@&#BG5PPGB7   :7
&#&&&@@@@@@@@&57777?JJY57:::::::...:??. . .:^..                        ...::::^:::^:::^:::^:^J?!^^!JG&@@&#BGGP55GGG~    
B#B##&##&#&&@@@Y?77?YJ??YJ^::::::^^^:^^:::::...                       ....::::^:::^::::::^:^~ .~JG&@@@@&#BGGGPPPPGGGJ!^:
BGBBBBBBBBBB#@@B!7JJJ????JY^^::^~^^^^^:::::....                        ....::::::::::::::::~GB&@@@@@@&&#BGGGGGGPPPGGGGBB
GGGBBBBBBBBBBB&@#?^!YY????JY~^^^~^^^:^^:::::.....                     .........:::::::::::^[email protected]@@@@&&&&&#BGGGGGPPP5PPPPPGG
GGGGGGGBBBBBGGG#&@#J~^~!77?J5!^^^::::::.::......                       ..............:::::[email protected]@@@&&&&#BBBGGGGGPPPPPPPPPPPP
PGGGGGBB#&#BBGGGGB#@@BY!^..:!?~^::::::..........                         ..............::!&@@@@&&####BBGGGGGGPPGPPGGGGGG
GGGGB#[email protected]@#BBGGP555GG#&&&BP?~:?~::.............                  ...::^::. . . .........^[email protected]@@@&&@#P55PPGGGBBGGGGGGBBB###
BBPJ~:[email protected]#BBGGPP5YJJJY5PGB#&&&#P:........         .:~~~~~~!77?YYY5PPPPPPPY:  .. .......^[email protected]@@@@&@@@@#GY7~:^~~!??JJJJJJJ??
?^.  [email protected]@#BGGGGGP5YJJ??J?YYYPGB#@5:....   .        :PBBBBGGGGGGGPPPPPPPPPPG!     ......7#@@@@@&&&@@@@@@@@#GYY???YYYYY5PB#
     [email protected]&[email protected]~.               ?BGGGPPPPPPPPPPPPPPPPG5: . .. . [email protected]@@&&&&&&&&&@@@@@@@@@@@@@@@@@@@&&&
   ..J&&&&#&&##BBBGGPPY5YYYJYJJ5B&@5^.              JGPPPPPPPPPPPPPPPPPGY:....    ^[email protected]@@&##BBBBBB##&&&&&&@@@@@&&&&&&###BB
.^!7???JJ?!!~?PB#GP#&&&##BBBBBBB###PPY~.             !PGPPPPPPPPPPPPPPP7......  :!#@@&BBGGGGGGGGBBBB#&&&&&&&&&&&&&&###BB
7?J?7!^..       ...:[email protected]~:           .?PGPPPPPPPPPP5?:....  .^~~::!YB#BBGGGGGGGGBB###&&&&&&&&&&&&&&&&&&
!^:     .^77JYYY5Y5Y7~:.....::^~P&@@@@@&G5Y?!:.         .~?Y5PPP5Y?~:.... .^JY7.      ~?GBBGGGGGGGBB#&&&&&&&&&&&&&&@@@@@
   .^!?5PPGPPP5J?!~^~77!~:.     [email protected]@@@@@GJ7?JJJ7~:          .:::.. ... [email protected]@&BPYJ7~:    :?5GGGGGGGPPGB&@@@&&&&&&&&&&&&&
^?YPGGGPPPP5J7~:      .^[email protected]@@@@@&577!!!7JYJ7^.              .^?5GG#@&&BGGGPGG5J!^   ^JPGGG5?5PPPGB#&@@@&&#######
GGPPPPP5Y7~:       :^!7???JGG#&&&&@@@@@@@B?!!!!~~!7JY5Y7^.       .^?5PPYJY&@&###BGGGPGGGG5J!: .YGG? .:~7Y5PGBB#&@&&#BBBB
PPP5Y7~.     .:!?YY5YJ7~:. .^^:^^[email protected]@@@@@P!!!!!!!!!7?Y5P5Y?!^^[email protected]@BYYYYG#BBBBGBGPP5J!^5B?      .^~?J5PGB###BGG
Y7^.     .~?5GGBP5?!^:              [email protected]@@@@&[email protected]@[email protected]@G77JPGGGP5YJJYJ77!^:.     .:~!?Y5PGG
     .~?5B#BG5Y?!:.                  [email protected]@@@@&[email protected]@@@@@@@@@@#5!..:~?Y55YJJ??777!~:.         .:^
 .~JP#&&#GPY?~.                  .   :#@@@@@@57~~^~7JJ??????7?7?77?7!7777J&@@@@&@@@@@@@@&P7:  .^^~~7?JJYYYYJJ7!^.       
5##&#BBPY!:                     ~GPY5P&@@@@@@@G!^^^^[email protected]@@@?!7?5G&@@@@@&BGY7~:     ..:^~7?JJY?!^:.  
BBGP?!^.                        [email protected]&&&&&&&&@@@@@B!^^^^^[email protected]@@@P^^:::^7YG#&&&&&&&#G5?~:..        .::^~~~
J!^.                            [email protected]&&&&&&&&&@@@@@B7^^^^^[email protected]@@@#P?~^:.::^7YPB&&&&&&&##BBP5J7!~^..     :
                               :&@&&&&&&&&&&@@@@@#?^^^^^^[email protected]@@@@@@&B5?!~::::^~?YPB#&&##BBBBB####BG5J7!7
                               [email protected]@&&&&&&&&&&&@@@@@&5!^^^^^^[email protected]@@@@@@@@@@&#G5?!^::.:^~7J5GB##BBBBGPGGB#&&&
                               [email protected]&&&&&&&&&&&&&@@@@@@B?!^^^^^^[email protected]@@@@@@@@@@@@@@@&B5J!^:....::^~7JYPGB##G5Y5G
                              [email protected]&&&&&&&&&&&&&&&@@@@@@&P!^^^^^^^!7?7!!~~~~~^[email protected]@@@@@@@@@@@@@@@@@@@&B5J!^:::.....::^!JG&&G?
                             ^&&&&&&&&&&&&&&&&@@@@@@@@@&5!^^^^^:^~!!!~~^^^^[email protected]@@@@@@@@&&&&@@@@@@@@@@@#GY7~^::.......:!5&&
                            :B&&&&&&&&&&&&&&&&&@@@@@@@@@@G?~^:^^^:^^~^^^^^^#@@@@@@@@@&&&&&&@@@@@@@@@@@&#BPJ!~^::..::..!#
                           :B&&&&&&&&&&&&&&&&&&&&&@@@@@@&5P5!^::::^^::^:~:[email protected]@@@@@@@@@@&&&&@@@@@@@@@@@&&&&&BY?7~~^:::::.~
...                       7#&#&&##&&&&&&&&&&&&&&&&&&&@@@#!~JPJ~^:::::::^^:[email protected]@@@@@@@@@&@@@@@@@@@@@@@@@@&&&&#G5J?!~^::::::
:.                      !P&&######&&&&&&&&&&&&&&&&&&&&&&#7::^?5?~^^^:^~^:[email protected]@@@@@@@@@&&@@@@@@@@@@@@@@@@&&&B#GY?7!~~^:::::
                      ~G&&&#B#######&&&&&&&&&&&&&&&&&&&&##!:..:?PY77?7^::[email protected]@@@@@@@@@&@@@@@@@@@@@@@@@@@&&&&G5J?!!~^^^::::
                    ^5&&B#GG##B&#&&&&&&&&&&&&&&&&&&&&&&&&P~:::..^?Y5?^::^#@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&#B5J?7!~~^^^^::
                  ~P&#PPYY5PPG#&&&&&#&&&&&&#BB&&&&&&&&&&Y. ^:.... ..:...:&@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&G5J?7!~~~^^^^::
               .7G#GYYJJJJYY5PB#&&&&&&&BPJ7YY~!5B&&&&#Y^    ::..   .  ...#@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&#GYJ?7!!~~~~^:::
             ^YBBPY???J?JJY5PGB&&&BGY7?J5::#&B: .:^^:.       .::.    ...:#@@@@@@@BGBPYYYJJ7!!77?JYG#@@&&BB5J?7!!~~~^^^::
           :5&#G5?7?77?JY5PGG#&G??YYY^B&&B~!&&#~              .:::.....:^#@@@@@@@5^..        ....:^:[email protected]&&#G5J7!~~~^^^^::
...... .  ^#&#B5J?7777??JY5GBJ^  7YGP7YGB##77&&&?               :^^::^:. ^5PPG&@@@@5?G5PGGGGB######5. ?&&&B5J?7!~~^^^^::
777!!:...^B&&&#PYJ777777JYY5PY?. ^PB##7JY5PG775PY:                .:.         :?P#@@5Y&&#GGPP555YYJGY. !&&B5J7!!~~~^^^::
^::~Y^~!5&&&&&BG55YJ??777?JY55P7. :!7?~!GB#&5?&#BBJ.                             .^?B?5&G^5?7~.5YY!:5?. ^B#5J77!~~~^^^::
[email protected]##&&&&&&###PPP5YY?7777?JYY5Y7:      ..^:.7?JY5~                                .?7B#7^!~: ?5?! ^J?: :GGJ?7!!~~~^^^:
[email protected]@@@&&&&&&##BGGPPYJJJ77!!7??JY5Y^                                                  7J&B.:^   :~:~^!J?: .5GJ77!!~~^^^^
[email protected]@&&&&&&&&#BBBGP5YYJ???7!!!!7??JJ7                                                 :75#J ~5^    !7:.7J:  YBY77!!~~^^^
[email protected]@&&&&&&###BBGGP55YYYY??7!~~~~!7777.                                                ^75#5J?.       7Y^!:  7BP?7!!~~^^
[email protected]@&&&&&&&#####BGGPP5YJ??7!!~~^^~~!77^                                                ~?Y55P!^7:   ~#G~BJ   ^PP?7!!~~~
[email protected]@&&&&&&&&&&###BBGPP55YJ?7!!~~^^^~~!7^                                                ~J5YY5GBPPJ:Y#!P#J    .5P?7!!~~
[email protected]&&&&&&&&&&&&&####BBGG55Y?7!!~~^^^^~!7:                                                 ^JGPYY5#BGB?Y#P.      5P7!!~~
*/
    // minting

    function mintSpecific(bytes32 tid, address to, uint256 tokenID) external onlyOwner tidCheck(tid) {
        tidUsed[tid] = true;
        _mint(to, tokenID, 1, "");
    }

    function mintBatch(bytes32 tid, address to, uint256[] calldata tokenIDs) external onlyOwner tidCheck(tid) {
        tidUsed[tid] = true;

        uint256[] memory batchAmount = new uint256[](tokenIDs.length);
        for(uint256 i = 0; i< tokenIDs.length ; i++)
        {
            batchAmount[i] = 1;
        }
        _mintBatch(to, tokenIDs, batchAmount, "");
    }

    function mintRandom(bytes32 tid, address to, uint256[] memory eligibleTokenIDs, uint256 numberToMint) external onlyOwner tidCheck(tid) {
        require(eligibleTokenIDs.length > 0, "No eligible tokens");
        require(numberToMint > 0, "Minting nothing");
        require(numberToMint <= eligibleTokenIDs.length, "Not enough eligible tokens");

        tidUsed[tid] = true;

        uint256 remainingLength = eligibleTokenIDs.length;
        uint256 seed = uint256(keccak256(abi.encodePacked(tid))); // tid is randomly generated by the backend, so it's safe to use it as a seed

        uint256[] memory batchTokens = new uint256[](numberToMint);
        uint256[] memory batchAmount = new uint256[](numberToMint);

        for (uint256 i = 0; i < numberToMint; i++) {
            uint256 rand = seed % remainingLength;

            batchTokens[i] = eligibleTokenIDs[rand];
            batchAmount[i] = 1;

            // update the seed
            seed = seed / remainingLength;

            // remove the random element by swapping it into the "last" slot, then ignoring it
            eligibleTokenIDs[rand] = eligibleTokenIDs[remainingLength - 1];
            --remainingLength;
        }
        _mintBatch(to, batchTokens, batchAmount, "");
    }

/*
............     ..........::::::^^:^~!!????JJJJJ?7!~^^.  .                                                             
..........  ......::::::^^^~!!!!!~!!!!!!!7777??JYY5GB##BG?^^   .   .                                                    
  .......    .:::^^^^^^~!77!~^^:::::::::^^!JPGB#BBBBBBBBGPPP!:.:.::                                                     
.............::^^^^~!!7!~^::.......:^^^~!75BGBBBGGBBBBBBBBBBB5J^.        .                                              
...    .....:::^~!!7!^::.......::::^!7JYYY55GBGGBBBBBBBBGGPYYYGGPJ   .                                                  
..     ....::^~!!~^:......::::^^~7JYPYYJJ555GBBBBBBBBBBGPGPPBBBBB! .~7BJ:  :^:                                          
      ...::^~!!~:.....::::^^!7J55P55YY55YGGGBBBBBBBBBBBBBBBBBBBB5 ?BB!:YB7  :PY~                                        
     ...:^~!~:......:::^^!?Y55YYYYY5PGPGBBBBBBBBBBBBBBBBBBBBBBBB55BBBBY :!:  ^PPY.                                      
    ...^~~^.......:::^~?JYYJ???7???PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBY  ..  ~G5:                                      
    .:^~:.  .....::~7JYY?7!!!!!!77JBB#BBBBBBBBBBBBBBBBBBBBBBBBGGBBBBBBBB?      !BY:                                     
   .^~:. .....::~7JJYY?77!!!!!!!!YB#BBBBGPPPPPGGBBBBBBBBBGGGGPPGGBBBBBBBB:      YGP7                                    
  :^:.......:^!7??JJJJ??7!!!!!!7P#BBG5?77~~!YGBBBBBBGGGGGGGGPGGBBBBBBBBBBJ      ^5J7!.                                  
.:.. ....:^~!777777?JJJ7777!77YBBBBJ!~^:::!5BBBGGGGGGGGGGGBBBBBBBBBBBBBBBY  !!  :57!~!.                                 
.   ...:^^~~~!!!777?JJYJ?????GBBBGJ!^::::JBBGGPPGPGGBBBBBBBBBBBBBBBBBBBBB^.PP57 :G5!~~7.         .....                  
   .::^^^^~~~!7777??J??JJJJ5BBBBGY7!~^:!PBBGGGPGGGBBBBBBBBBBBBBBBBBBBBBBY!GBPP~ 7BGJ7!7?.          .:...                
....:::::^^!??JJJJYYY5P5PPPBBBBB5J?7!!YBBBBBGBBBBBBBBBBBBBBBBBBBBBBGGBBGPBBBGB..GBG5Y?7P5:           ::..               
........:~?5JYY5PGGBGPGGPGGBBBBG5YJJYGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB5:PBBGG5YJJG5:            ...              
....::^!7YY55GBBBBBBBBGGGGBGGGPPPGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBYGBBBBGG55YPG7~^.           .              
^~777JJJJYPGBBBBBBBBBBBBBBBGGBBGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBG5Y?J??!~~.                        
YYYYYJJYPGBBBBBBBBBBBBBBBBBBBBBBBBBB#BBBBBBBB##BGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPY?7!!!!~~:..                     
JJYYY5PGBBBBBBBBBBBBBBBBBBBBBBBBBBB#BBBBBBB#P5#PYBBBBB#BBB#BBBBBBBBBBBBBBBBBBBBBBBBBBBG5J77~~~~~^....                   
Y5PGGBBGGBGBBBBBBBBBBBBBBBBBB#BBBBB#BBB####?.P#~Y#######BB#BBBBBBBBBBBBBBBBBBBBBG#BBBBBBG5J?7!!~^......                 
PGGBGGGGBBBBBBBBBBBBBBBBBBBB##BBBB#######P:  GG 7####&JPBB##BBBBBBBBBBBBBBBBBBBP.#BBBBBBBBGG5YYJ~::::..                 
GBGBGGBBBBBBBBBBBBBBBBBBBBB######B####&&[email protected]&###&:^#BB#BBBBBBBBBBBBBBBBBBB: P#BBBBBBBBBBBGYJ!:::::.                
GGBBBBBBBBBBBBBBBBBBBBBBB#GB#########&&@&@@@@@@@@@@@@@?^JBBGBBBBBBBBBBBBBBBBBB7  7&BBB#BBBBBBBB^?P!: .::                
BBBBBBBBBBBBBBB##BBBBBB###YB##########@@BY?~^[email protected]@@@@@@@@&7YB5^BBBBBBBBBBBBBBBB7   .G#BB&#BBBBBBB^ 5?.  ::.               
BBBBBBBBBBBB########B##&&&####B#####G^?P!.  .&&GY##5G#@@B.7G..GBBBBBBBBBBBBB:     7###JPBBBBBBB: ^:   .:.    .          
BBBBBBBBBB############&&&####BB##&#BB.. ..   P~:.:[email protected]  ~:  J#BBBBB####G.  . . 7###:~#BBBBBB!  .    :.               
BBBBBBB#############PY&&##########&##!..      ::.    .:?        ^G#BB#B&&B!7B&@@@@@&&7  BBBBBBBBY .    ^..              
BBBBB#############G?~#&&###########&#G:....    .                  :55: JY:[email protected]@@@@&&@@@B5!B#BBBBBBB..    ^:               
#####&########BBBJ^:^&&##############BB^...                              .#B&@@@GB&#&@@&&BBBBBBBY      ^:               
####&&&&&&&&@B.:J.  .&&##############5JG?....                            .^:^P5~^!^:BBG##BBBBBBB! .    ^.               
####&&&&&&&&&@5 ..   [email protected]&##############5^!?^.                              :     .   .~B#BBBBBBBY  .    :                
#######&&&&&&&&B. .   !#&&&############G^ ..                                   .    ^###BBBBBB?       ..                
&&####&&&&&&&&#&&^ .^.  !G&&&&###########!                                         !###BBBBGG7.  .    .                 
&&&&&&&&&&&&&####&? .!!.  .~5#&&#####&####Y.                                     .Y&##BBGGGBB57~~.                      
&&&&&&&&&&&&&######G: .:      :JB&&###&&###B:                                   ^G##BGGBB#BGJ77!^                       
@&&&&&@&&&&&&&&&#####P^          ^P&&##&&###B     !PGGGGBGP5J?!^.              .:P&&###BGYJ?!~~^:                       
@&&&&@@&&&&@&&&&&&####&B5^         :P&#&#&###:   .Y!!!7?J5B&&&&&#BPJ~:           B&##BBPYJ7~^^^:.                       
@@@@@@&&&&&@@@@&&&&##BBB##Y          !#&B7&##:   ^?~~^^^^^~!JPB&@@&&&&&!        [email protected]&#BBG5YJ77~:...                       
@@@@@&&&&[email protected]#^^@&&#####GP5BG          .5&^7&B    ^?~~~^^^^^^~!7J5B&@@@G         B&###GP5Y?!77~^.                        
@@@@&&&&# ?&   #@&&###BBG5JBG           ?J &~    .?~~~~~^^^^^^^!77J#@Y         G&&##GP5Y??7!!!^:.                       
#@@@&&&&7  .   [email protected]@&#&&##GP5J&G.          . !      7!~~~~~^^^^^^^~!!?^        [email protected]&##5~:JJ!~?!!^   .                      
 [email protected]&&&&&!       [email protected]&#&&P##[email protected]:.                  ?~~~~^^^^^^^^~~:         ?&&&&P:  ^7. .?!!                           
  [email protected]&&&&Y       .#&#B&?.Y#GYJB#~:..                .!~^^~~^^^^^~:         ~#@&&B~   .:   ~!!~ ..                        
   :G&&&&.        P&B?#~ .755Y#P^....                ^~~~~~~^^.         [email protected]@&G7.  ..^7?YPBBBBB##BGPJ!:.                 
     ^B&&P         !#^.Y7   .:!#5^......               ..:..         .?&@@@&BPP557^:^7J5GB#&&&##BGB#&&#G?:              
       ^YG?.         .  .:.     GJ:........                        [email protected]@@&&###BBBB##B5?!^::^~JG#&##GYYP#&&#5^            
          ..                    .G7:..........                  :Y&@&&#BBBBBBBBBBBBB####BGJ!:.:7G###BY7JG#&#P^          
                                 :B!:..........:.           .~5B&##BBBBBBBBBBBPPPPPGB#######B5~. ^Y###BY~!5#&#P^        
                                  ?B~:...........::..    .?G&######BPJ?!~~^:.        .:~JP#####BY: .7B##BJ^^Y###5.      
                                   G5^:.............::^!G&&#####GY~.                      .~5#####5^  !B##G7:^5##B!     
                                   .#7::.............~#@&####GJ~.                            .?B####5^  7B##P^.~G##5:   
                                    5B~::...........?&@&###G!:.                                 7B#BBBJ. .?###J:.7B#B7  
                                    :&?^:::.......:[email protected]@&&&B7:..                                   .?BBBBG^  :5##B!.:Y##P:
                                    .&P~^::::::..~#@&&&@&#B5!.                                     .JBBBBJ   ~G##5:.~G#B
                                    :@G!^:::::::[email protected]@&&&&&&&&&&#5^                                     .?BBBP:  .J##B?..J#
                                 :?P#@B?~^^:::7&@&&&&&&&&&&&&&&&P~.                                    .7GBB?.  ^GBBP^.^
                              [email protected]&B57~^^[email protected]@&&&&&&&&&&&&&&&&&&BY~.                                    ^?PP!   YB#B?.
                            :YBBBBB&@&#[email protected]@@&&&&&&&&&&&&&&&&&&&&&&#5^                                     .:....?###P
                         .7G#BBGGB&@@BBGP#@@@&&&&&&&&&&&&&&&&&&&&&&&###&B?:                                         :75G
                       :Y##BGBBB#&@@@#&&@@@@&&&&&&&&&&&&&&&&&&#B5&&&#######G!.                                          
                     :P##BB#G55J7&@@@@@@@@&&&&&&&&&&&&&&&&BP5PY J&&###########J.          .                             
                   ^G&#BBG57^:^:[email protected]@@@@@@@&&&&&&&###&&#PJ~^~G&5.:&&##############J.        :.                            
                  [email protected]@&#P?^::^:::[email protected]@@@@&&&&&&&&######G&#[email protected]@^  B&#################J:      .:.                           
                 [email protected]@#Y~::^::^^^[email protected]@&&&&&&&&#######B^@@G#[email protected]?  7&####################5:     ^:.                          
                [email protected]@G!:::^:^^~Y#&&&&&&&############[email protected]@B   B#####BBB###############5^.. :~:.                         */
    // Token data

    function uri(uint256 tokenID) public view override returns (string memory) {
        Token memory token = tokens[tokenID];
        return token.uri;
    }

    function name(uint256 tokenID) public view returns (string memory) {
        Token memory token = tokens[tokenID];
        return token.name;
    }

    function totalSupply(uint256 tokenID) public view returns (uint256) {
        Token memory token = tokens[tokenID];
        return token.totalSupply;
    }

/*
                                        [email protected]@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@&&&#G?:.                                
                                     :[email protected]@@[email protected]@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@#GGGGY^                               
                                   ^[email protected]@&5^:B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BP55PJ^                             
                                 ~#@@&?. :&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BP5Y5Y~                           
                              :Y#@@#!.  ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#PP5YYJ^                         
                             ?GGG5!.   [email protected]&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P55YJ?:                       
                           .5#PGY:    J&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPYJ?~  .                   
                          ^5G57:     5&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@##BGY7!.  .                 
                        :Y5Y?:      Y&Y#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@&##GJ7.  ..               
                       !G5J7.      ^&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@&#Y7:  ..              
                   . .PBPY!        &5^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJ:  .^.            
                     #@#P7        7#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&Y:   ~.           
                   ~&&&&5.        BB7:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B:   ^:          
               ^[email protected]@&&&?        .&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&~   ~:         
            ^Y&@@@@@@@@&5.   .~YG&&..~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J. .!.        
         :5#@@@@@@@@@@@@@@&&&@@@@@@5. .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B: .!.       
       .7&@@@@@@@@@@@@@@@@@@@@@@@@@@&P?!7G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&! .^.      
      :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5. :      
.... !&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G7&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#: :.    
 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~.:&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~.:.   
 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B   .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G?:~.  
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~    :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJ^^. 
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#      ^@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P?J:
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~       :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&B5#
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&B
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B: . ^@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:.~?5PG##B#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@J     .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BBP?!^.... ^@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@#~#@@@@@@@@@@@@@@@@&^       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@B~.......    [email protected]@@@@#~?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@P:^&@@@@@@@@@@@@@@@@5J555PPPP#@@@@@@@@@@@@@@@@@@@@@@@@@@@G:..:....:[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@J..^@@@@@@@@@@@@@@@G^::^^^^~!Y&@@@@@@@@@@@@@@@@@@@@@@@&#@P..   :[email protected]@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@&^ . ^&@@@@@@@@@@@@@G!~^::::^[email protected]@@@@@@@@@@@@@@@@@@@@@@#J7&Y.   :[email protected]@@@@@@@@@@@@@#G##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@P    ^&@@@@@@@@@@@@#?~YPG&&@&@@@@@@@@@@[email protected]@@@@@@@@&B?^ ^B~    .BB?^^@@&P7P#[email protected]@G:^:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
~    :@@@@@@@@@@@@@#?5B&@@@@@@@@@@@@@@@@&#&@@@@&BY!.    .~.      .    PY^...?!~J&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    [email protected]@@@@@@@@@@@@@@@@@@&&BG5?&@@@@@@@@@@57!::.                        :.... .^?J..^^[email protected]@@@@@@@@#B#@@@@@@@@@@@@@@@@@@@@@
   [email protected]@@@@@@@@@@@@@@@@@@@G!^::^#@BG7PBJ?5#Y                              :^::::^?::...:@@@@@@@@@GBP5&@@@@@@@@@@@@@@@@@@@@
  [email protected]@@@@@@@@@@@@@&&@&GP5YJ:   .5G!. !?:.~:                             [email protected]@@@@@@@@G#[email protected]@@@@@@@@@@@@@@@@@@@
 [email protected]@@@@@@@@@@@@@#J75#?....~^.   ~?~...:~!.                            .... ... .....:&@@@@@@@@P#[email protected]@@@@@@@@@@@@@@@@@@
&@@@@@@@@@@@@@@@G!~^~PY.....:~^:.^~^^:::.                           [email protected]@@@@@@@P7#BB77!&@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@G7~~~G5......::.:.....                              ......  ... ...&@@@@@@@&:[email protected]@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@BY?!7PP:..........                 .                   ....   [email protected]@@@@@@@75B577P&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@#Y7!75G:......                                                 :&@@@@@@@#GB55#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&P?7J5G:....                                                  [email protected]@@@@@@&PGB&@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@B?!!YG:.                                                   ^@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@5^.?G.                                                  .&@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@P^?5                    :JY55?!777!77!^.             .#@@@@@@@@@@@@&P7&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#&5.                [email protected]&#G5J?77!~~!!!7            :&@@@@@@@@@@@@@&G?&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J                .&&#Y7~~~^^^^^^^~7           [email protected]@B&@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P.               !&G?7!~~^^~~^^~!^          ~J^.?&@@@@@@@@@@BP5Y7!&@@@@@@@@@&@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]&?.              .J5?!~~^~~^~~~:             :G&@@@@@@@@@@&B5YY?!!#@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@&Y:               :~!~^^^::.             :P##[email protected]@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^ @@@@@@#?:                                 ^P&#[email protected]@@@@@@@@@#BG5YY5PPY#@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B :@@@@@@@@@#J:                            !G&&[email protected]@@@@@@@@@&#G5YYY55PP&@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@? [email protected]@@@@@@@@@@@&P!.                     .J&&#BY??J7#@@@@@@@@@@@@BPPPYY55Y555B#&&&##&@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@. &@@@@@@@@@@@@@@@@BJ^                !G&&#[email protected]@@@@@@@@@@@@@#GPYYY?!!~!!J5JJ?J&@@@@@@
@@@@@@&@@@@@@@@@@@@@@@@@@@@@G [email protected]@@@@@@@@@&&@@@@@@@@&P!.         ^Y#&&[email protected]@@@@@@@@@@@@@@@&B5YJ!!!~~!!~~!~!&@@@@@
@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@7 &@@@@@@@@&##&@@@@@@@@@@@&B?:. .^YB&&[email protected]@@@@@@@@@@&@@@@@@&GYJJJ7!77!!~~!&@@@@
@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@&@&&@#&@@@@@@@@@&&&&&#B&&&B5J7!!~~~~~~!~!!?5G&@@@@@@@@@@#Y5#@@@@@@&BBGGP5JJJ?77#@@@
@@@@[email protected]@@@@@@@@@@@@@@@@@@@@Y.&@@@@@@&@&##&B&@@@@@@@@@@&PYPP5PYJ?7!!!~!!~~!!!?P#&@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@&&&#GP&@@
@@@@Y&@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@&&GBB#B#@@@@@@@@@@&GJ?777!!!!!!!!!~!7JG&@@@@@@@@@@@@@@@@@@@@@&#BGPPPG#@&&#BGBB&&@&&@
@@@&[email protected]@@@@@@@@@@@@@@@@@@@@^ &@@@@@&@&[email protected]@@@@@&&@&57!!!!!!7!!!7?YB&@@@@@@@@@@@@@@&P?!?P&@@&#####BP??77J5B&&BPY?5G&
@@@Y#@@@@@@@@@@@@@@@@@@@@: [email protected]@@@@@&&&[email protected]@@@@57&@&G?7!!!!!777JP&@@@@@@@@@&####&@@@&G?^..^[email protected]@&#B##&@&&#57!?5#@@B7^
@@#[email protected]@@@@@@@@@@@@@@@@@@@^ [email protected]@@@@@@@@@BB#&&&&@@@@&PY#@@@&[email protected]@@@@@@@&#5J~^::..^[email protected]@@@&P!...!G&@&BPPPB&@@###G#&@@&
@@~#@@@@@@@@@@@@@@@@@@@? .&@@@@@@@@@@@@@@@@@@@[email protected]@@@@@#[email protected]@@@@@@@#PJ!^:..       .7#@@@@@BJ~::~P&&&&B##&@@@&PY5#@
@[email protected]@@@@@@@@@@@@@@@@@@@?J&@@@@@@@@@@@@@@@@&GYP#@@@@@@@&P7!~!7Y#@@@@@@&&GJ!^:..             .^JB&@@@@#YY##&@@@@#B#@@@BYY5
&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@&G?7?YG#@@@@@&#B57~:..                     [email protected]@@@@@@&@@@&BB&@@#YY
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@&@@@&#[email protected]@@@&GPJ7^:..                           ^#@@@@@@@@@@&[email protected]@#Y
[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@&#[email protected]@@##&&&@G5JY7~7:  [email protected]@@&PJ!~:..                              J&&@@@@@@&@@&B5P&@#
.#@@@@@@@@@@@@@@@@@@@@@&#G5P5G5PPGG###BY#@@####@~        ~#@@#G5?!^:.                               [email protected]&##@@@@@@@@@@[email protected]
^@@@@@@@@@@@@@@@@@&G7!!J5PGPYPGBBP?!.   [email protected]@@&##B     .^5&&&#GJ!^^:..                               7&&#GG#@@@@@@&@@@B5J5
[email protected]@@@@@@@@@@@@@&J^.7G&&GJ7JPPY7:         ^@@&##B7?5B#&@&##G5?~^:..                                [email protected]@#GPPB&@@@@@@@@@@#5J
[email protected]@@@@@@@@@@@&~  ^&@&J~JY7^.              .&@@&#&&&&###BBB5?7~::.                                [email protected]@@#GPPG#@@@@@@@&&@@#5
&@@@@@@@@@@@Y    .~. ?^.                    [email protected]@&&@&@#&&@#B5!^:...                               ~&@&G55JJYP&@@@@@@&&&@@&
@@@@@@@@@@@!                                 7&&#P!^. .?J?7~^::.......                         [email protected]@B5?7!!!77Y#@@@@@@@&&@@
@@@@@@@@@#.                                                ....                               [email protected]&G?~~^^^^^^[email protected]@@@@@@&&@
@@@@@@@@G                                                                                    [email protected]#5!^^::::::::^~Y&@@@@@&&#*/
    // Override for token total supply

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                Token storage token = tokens[ids[i]];
                require(ids[i] < numberOfTokens, "Invalid ID");
                token.totalSupply += amounts[i];
            }
        }
    }

/*
JJJJJJYYY55555555PP55PPPP5P5P5Y55Y555PGPPPGGBB#&&#G5J7^.                            .:!JPB&&##BGPPP5PP5PP5555YJJJJJ?????
YYJYJJJYY5555PPPP55PPP555P55555555PPPPGBB#B#B5?~.            ...:::::.:....               .:7YGB##BGPGP5PP555YYYJJJJJ???
YYYYYY5YY5555P5PPPPP5555555P55P5PPPGB##BP7^.         ......::......:::::::::^^^:..    ...       .~75G##BGPPPP55YYYYJJJ??
JYYY5555P55555PPP5P5PPP5PP55PPPGB##B5!.                     ..^.  .............::^^^...........      .^?PB#BGPPP55YYYJ?J
JYYYY555P5PP5P55555PP55P5PPPGB##P7.                       .........................:^^^..                 ^YB#BG5Y5YJJYJ
YYY5YY555PPPPP5PPP5PP55PPGB##5~.                          ............................:^^..                  .7GBG5JYYJJ
5555555555PP5PPPPPPPPGGGB#G!.         ..              ...::^^^~~~!!~~^^:::..............:^^.                    .JBBYJJJ
55555PPPP5PPPPPPPPGGGG##5^          ..       .....:::::::::::.:::::^^~!!7????!!^::........^!~.                    .JB5JJ
5555PPPPGPGGGPGGGGGB##Y.         .... .......                              .:^!7JJJ7~^:.....~7~.                    :5B5
5PPPPPPPGPGGGGGGBBB#P:         .^:...                                             ..^!7?7~^:.:7J~.                    !#
PPPPPPGGGGGGGBBBB#B^          ::.                                                       .:~7?7~~JJ^..                   
PPPGPGGGGGGGBBBB&J                                                                           :~JYGBJ:.                  
PPPPGGGGBGGBBB#&~                                                                               .^JG#5~.        .       
GGGGGGGGBBBB##&~ .                                                                                  .75P?^..... ..      
PGGGGBBBBBB#&&~..                                                                                      .~JY7^....:^     
GGGGGGBBB##&@!^.                                                                                          .^7?!^..!!.   
GGGGBBBBBB&@G^.                               .::^^~~~~~~~~~~~^^:::..                                         :7?!^YJ:..
GGGBGBBBB#&@#.                          ..~5###BGGG5555YYY5YY555PPPGGGGGP5Y?!^..                                .^?Y&Y^^
GGGBGBBB#&@@J            .        ..       :5G?7!!!~~~~~~~^~~^^^^^^^^^~~!7?JY55P55J?~:.                            :G&7^
GGGBBBB##&@P             .~.     ..          ^G?7!!!!!??~!~~~~~~~~~^^^^^^^^^^^^~~!7J5PGGPJ~:                         #B~
GGGBBBBB#@@~               .  .::.            5P!!!7!!PY!!~~!!!!!!!~~~~^^^^~~^^~~^^^^^~!?YPBGP7:.                    ^&5
GGGBBBBB#@#                 ^^:..         :^:?#7!!!!!!G5777!!?G7!!!~~~~^~^~7~^~~^^~~~^~^^~!!7JPBBP?^.                 B&
[email protected]@!               :~:....       :J?77P?!!!!!!!G&Y7777?PY!!!~~~~~^^^7J!^~^~^~~~^~^^JJ!!!7?YPBBP?:              [email protected]
GGBGGBB&@G              .~^....:.     .JY?7!!!~~!!~!!!BBBPGJ?J?PJ!!~~~~~~~^^~Y?~^~~7?7~~~^7G77!!!!77?YB&#P!.          .&
GGGBB#@@Y              ^!:.:..:^     ~PJ!~~~~~~~~~~~~!#~~&P?7JJ?Y?~~~~^~~^^^^^JY!!~~!~!~~^^BY?7!!!777??J5&&&BJ:        P
GGGB&@#^             .!!:::.::^.    ~G!^^::^^^~~~~~~~G5..J&5J??77Y7!^^^~!777?JJG#57!~~~~^^^YBJ7!7!!77??JJ5&BB#&#Y^     ^
GGB&&!              ^7~:::::::!    .B!^::::::^^~~~~~YB.  .YGJ?7?755PP??!?7!~~~~5Y5BJ!^^~~~^J#J7!!!!777??JJ&&GP5PB##?:   
G#&J               ^?^:::::::!!    55::::..:::^^^^^?&:   ::YBYGGPPB^JP?~^^~~^^^P~ 7#G?^~^^^?#[email protected]&G~ 
#G:               ^J~::::::::Y^   .#!:::...::::^^^7B!    77YGP7~GYG: !B?~~~~~~~G.  .5&P!^^^J&[email protected]#5???JYY5B&B
~       ::       .Y!:::^~::::P    !B~.:......:::^!P?    !?: !~::?BYJ  ^&GJJJYJB#!7^. ~&&5!^Y&[email protected]#P????JJJ5G#
      :^^        7?^:::~^:::~5    P?~7.......:^^~Y7    :.  .Y:::.?GG^[email protected]@@@@@@@@@@@&G?!P&&[email protected][email protected]&&#PJ?JJ??Y5
    ^~^~.    .  .P~^^:^!::::5!   .P7 !!:.....^^^J7.        !^:::[email protected]@@@@@@@&&&@&?YP#&@@@&&&@@&5?7!~~~~~~~~~5G.^Y&#G5?777Y
  ~!~^~~     .  ~5^^^:7^::::G.   :J!  !!:....7^??.         !.:J##57^#&&###5&&&&Y    [email protected]@&7#&57!!~~^^~^^~~PJ   ^&&&G5YYP
^?!^^:?.    ..  JJ^^^~J.:::!P    .5~   !!....JYJ.          .^PY:   ^@BB#&#BBPGBG     .&#7  @&J7!!~~~^^^^^~B7  . ^&BBGB#B
J~:::!J     ..  5?^^:P!.:::Y?   .~#Y~^. ^7^..^B:          .:^.     .&J!!&Y~5.^??    :G7   [email protected]!!!~~~^^^^~!B:     GG5J?5G
^::::5^   7:..  GJ^^[email protected]::#7^[email protected]@@@@@@@&577!:.7.                    ?J..:~.   ~:   .:     [email protected]!~~~~^^~~~JP   .  PP?7?JY
::::~P  .?^?:.  PG7^G&&[email protected]@@@B7: [email protected]&B#&#BY!~^~                     ^:     .:.          .&B77!~~!~^~~~~~P~   .  #5?7!!?
::::5? .5~:^7   [email protected][email protected]&7^#@@5.    [email protected]~?5: :~                       . ....            [email protected]!~~~~^^~~~~!P.   . 7B?!!!!!
:::^B. P!::.!~   &&#@P75Y!G&@?     :&7^~5!:::                                            &G?7~~!~^^~!~^~J~   . :#Y7!~~~!
:::7G.GY^:...~!  ^@&@P775! .757.    :?:                                                 Y#Y7!!!~^~!7!~^!J     ^#P?!!!~!!
^!755JG^:.... :!: [email protected]@#?7!YJ   ...     ^:.                                              ^&5J777!~!77!~~~5^..  7&G?7!!!!7P
YP5PB#?^:.....  7#?J&&J!!~JP:           .                                              #GYJJ?7?7!!!~~~5J.  :B&P?!!!!!!7Y
7!~~B#!::.......B#5JJY?!~!~7P!               :.                                       P#55P5J7!~!7!!!JG. :5&#Y7!!!!~~!?J
~^^^5#!^:::....J&Y7!!!~!~~~!7B7                                                      Y&GBB57!!!77!!7YY&5#&#5?7!~~~~~!7J5
^^::^P!^::::::^&B?!!~~^^^^~!7#J.                                                    ?&B#[email protected]&#P?7!!~~~~~!!?5#
:::::^~::::::^B&57~~~~^^^^~!YG:!                                                   ?&#&G?7JJ7!!!!5G~:&B5?77!!~~~~~~!7Y##
::..::.:::::!#@BJ!~^^^^^^~!?B~.^:                                                 Y&&#P??5J7!!!7P5:.5&J777!~~!!~!~!7J#&J
::::::::^^^?B##Y!~^^^^^^^~Y#7...~                        ....:~!!!!~~:          .5&&B5?YGJ7!!!JBJ..:&G?7!!~!!7!!777?G&57
::::::^^~~YP7G?~^^^^^^^^~P&!.   ::                .^^^^:^^~!!!!!~~~~~!^        ^7?&[email protected][email protected]!
:::^^~!!?Y!~5!^:::^::::~5P:      ^              .&@@YJJ???7!~~~~~~^~^^~      .~:^#5J?BB?7!7YGJ....:&[email protected]~~
:^~~!7?J!.~J^:::::::^!77:         ^              [email protected]@BJ7~~~^^~~^~~^^^^!:    .:. ~#YJ5BP77?5B5^[email protected]?777!!!!!7?JG&Y!~~^
!7J?!^: .J7::::::^~77!.            :              [email protected]!~~~^^^^^~~~~^~!^    ..  7BJJGGY7JP#P^.......##J??7!!77?YPP&#?~^^^^
Y?^..  !J~::..:^!!7~:..             ..             .YY7~^^^^^^~~~~!!:        JG?P#P?JP#P^[email protected]????JPBPJBP!^^::^?
...  ^?!:::^~!~^^:...                 ..             .:!!~~~~~~~!!:         5GY##5YG#P^   .   ...GP#55555B#Y:7G7^^:::^Y5
  .~?!^^^^:::~~:..                      .:..              ...:...         [email protected]#GB#P~.          !J.#GBB#B?..JJ^:::::7Y7^
:!7!~~^:.  .^:.           .                .:^:                          75J#@&&#5^.           .J!.#&B:...?J~:::::!J7^::
?7!~:   .:::.            ..                   .^^.                     .7:[email protected]@&BJ:.             .Y^[email protected]:7J!::::^!J7^:...
:.   .::..            .  .                       .:.                  :: [email protected]@B7:.               .Y^..J77J!::::^!J7^...   
  .::..                 .                           ..              ::.:#@#7:..                 ~?.^??!::::~JY7:..      
::..                                                  ..          :~:.!&&Y^....                 .G5?~:::~J5Y!:..        
.                                                       ...     .~~.:Y#B?:...                 :?P?^:^!?PPJ^.            
         ..                              .:.                   .~^:^J^^J:.. .              .!5GY!!?5B#BJ^..             
   .....                              .!J7:                   ~!::^!  ^~:....... .       :?#&#BBB#####BBP!::........:::^
:::..                              .!JY?!^.                  !~::~~   ^  ......... ..^JP#&&&&#########B?:           ..:^
.                               .^?J7!!!~:                  !~::~^             ..~JB&@@@&&&&&&&###BBB?.                 
                             .^7?7!~~~~~~:                 ~~^:^:            .?B&@@@@&&&&&&###BBBBBY^              ..   
                          :~7?7!~~^^^~~~~^                .7^^~^          :?#@@@@&&&&&&&#BBBBBBBBG!.                :^. 
                     ..^!77!~^^^^^^^^^^~!^.               J7~^~       :7P&@@@&&&&&&&&#BBBBBBBBBBJ:                   :~~
                 ..^!77!~^^^^^^^^^^^^^~~~^:.             !&P7J?  .^7P&@@@@&&&&&&&&#BBBBBBBBBBBP~.                     :!
            ..:^~!!~~^^^^^:::^^^^^^^^^^~~~^::....  ....:7&@&B&@@@@@@@@&&&&&&&###BBBBBBBBBBBBG~.                        .
   ..::^~!7777~~^^^^^^~~~!!!!!!777?JJ?7!!!~!~:...    ^P&@@@&&@@@@&&&&&&&&&##BBBBBBBBBBBBBBBP:                           
~7JYJYY??7!~~~^^^~~~^^^:::::....:... ..::...  .....!G&&&#&@@@@@@@&&&&&###BBBBBBBBBBBBBBBBB5:.                           
J?7!!~~~~~~^^^^~~.                  ...          :G&&#######&&&&###BBBBBBBBBBBBBBBBBBBBBBJ.                             
~~~~~^~~~^^^~~^.                  ..           .!#&####BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB7.                              
~~~~~~~~~~!~:                   ..            .Y&###BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB!                                
~~~~~~~~~!.                    ..            ~B####BBBBBB######BBBBBB#BBBBBBBBBBBBBBBB!                                 
~~~~~~~!^                     .            :Y#####BBBBB#PYP5JJYYJJJJY555PPPJB#BBBBBBG~                                  
~~~~~!7.              ..:...             .J######BBBBBB7~!Y####&&#&&#&&@&#PY&BBBBBBP:                                   
~~~~7!.           :~~~^:...            .?B######BBBBBBP:?^::~~^~^^:!~~~~7~?##BBBBBJ.                                    
!7??:         :^!~~:.                :JB##########BB#Y:^::..~^:~^~^77?~!7B&#BBBBBY.                                     
!~:        ^!!^..                  .JB##############J!GGB^.~7?YY:!5??J5Y#&#BBBBBY.                                      
         ^7^.                    .!G###BBBBB#######Y!#B#Y :YY5P!:Y~7BPY&&#BBBBBY.                                       
        :J.                    .~5BBBBBBBBB#######J7#BB5 :JJY57.!^Y&#5&&#BBBBBJ.                                        
         !~          ..:::^^^!JPBBBBBBBBBBB######!?#G#5 :PY55J.:^P&#Y&&#BBBBG^                                          
          ~.         .PBBBBBBBBBBBBBBBBBB#######!5&#G! :Y~^?P..:[email protected]&J&&&##BBY.                                           
*/
    // Operator filter
    
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}

/*
                                                                                                                        
                 .        ..........                                                                                    
             ........ ..^~^^^:::...                                                                                     
          .:::.......~7?7!~~^::....                                                                                     
      .:^^~~^:....:~?Y?77!~^^::.....                                                                                    
   .:^~^^~~~~^::^7Y5YJJ77!~^::............                                          ....                                
 .^^^^^^^~^~~~7YPP55YYJ?77!^^::...::::.                       :::.                   ..^:                               
::^:^^^~!7?J5PGGGGPPP555YJ?!^^^^!!^:.    .......             :~::::.                   .^~                              
::::^~?5B##########BBBGBGPJ77?J?^.....:^^~~^::..            ~7^:.....       .            ^!                             
::~J5B###&&&&&&&&&&####BGP5P5!:..~7JYJJ?77!~^:..           7Y!^::....:      ~!:.          :!                            
?PB##&&&&&&&&&&&&&&&&###BG?: .?GB######BGPJ7~^:..         ?P?!~~:::..::      5!::.         ^^                           
#&&&&&&&&&&&&&&&&&&&&&#Y^   7#&&&&&&&&&&&#PY7~^:...      J#Y?7!!~^^::^^~.    ~B~^:^.        :                           
&&&&&&&&&&&&&&&&&&&&&Y: .:7P&&&&&&&&&&&&#BG5J?7~~^::....J&B5JJJ?77!!~~~!^    :@J~^::.                                   
&&&&&&&&&&&&&&&&&&&Y^~Y#&@@@@&&&&&&&&&&&##BPP5YYYYYJ7~~Y&&BGP5PG5YJ?7!!~^:.  ^@BJ!^::.                                  
&&&&&&&&&&&&&&&&#Y75&@@@@@@@&&&&&&&&&&&&&&###BBBB##[email protected]&&###B###BG5J77!^:.. ^@&G?!^^:.                                 
&&&&&&&&&&&&&&[email protected]@@@@@@@@@@@@&&@@&@&&&&&&&&&#######&@&&&&&#&&&&##GPJ?!~^:..^@&#5J!^::.                                
&&&&&&&&@@@@&GP&@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&##&@@&&&&&&&&&&###G5YJ7~::[email protected]&&GY?~^:.                                
&&&&&@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&@@&&&&&&&&&&&###BBGP5J~^:[email protected]@&#PJ!^:.                                
&&@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&@@&&&&&&&&&&&&&#####[email protected]@&&B5?~^..                               
@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&#&@&&&&&&&&&&&&&######[email protected]@&&BY?~:..                              
@@@&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&B.#@&&&&&&&&&&&&#######&&&&B [email protected]@&&GY!^:..                  ...        
@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&Y  #@&&&&&&&&##########&&&&&? .&@@&B5?~:..     ..               ...    
@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&~   &@&&&&&&&&##########&@&&&:  ^@@&&GY7~:..       ..               ..  
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&@@&GP!: [email protected]@&&&&&&&&#####&&&&&@&&&G    [email protected]@&B5J!^:..    .   :.               :.
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&B5~.  .:[email protected]@&&&&&&&&&&&&&&&&&@@&&&~     &@&&GY?~^:..    .   .^               .
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#B&@@&&&&@&#5~.        [email protected]@&&&&&&&&&&&&&&&&&@&&&@!::.. [email protected]@&#PY7^::.    ?.   :!:   .          
@@@@@@@@@@@@@@@&@@&&@&@@@&#[email protected]@@@@@&B?:           :@@@&@&&&&&&&&&&&&&&@&&&&J:[email protected]@&&BPJ!^::    5Y^:::^?~  ~.         
@@@@@@@@@@@@@&&&&&&&&@@@@&&@@@@@@@@&#PJ^.         [email protected]@@@@&&&&&&&&&&&&&&###&Y        &@&&#BB?~^^.   !P.. ...7^ 7~         
@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@G^      [email protected]&&&@&&&&&&&&&&#&&&##&&7         [email protected]&&BP#?!~~.   !P...  ..? !?.        
@@@@@@@@@@@&&&&&&@@@@@@@@@@@@@@@@@@@::^7P&@#^   Y&&&J#@&&&&&&####&&#&&#Y.          [email protected]&#BGB7!~~.   7P.......!.~5:.       
@@@@@@@@@&&&&&&&&@@@@B!::@@@&#&@@@@@~     .?G:.G&&[email protected]&&&&&&&##&&&##B7..:~?YY?~:   #@&#B#P77!!    7G:......^:7Y^..      
@@@@@@&&&&&&@&&&@&?~G&7 [email protected]@G5G&5?P#@5        !&&B! .&&&&&&&&#&&&P~.^[email protected]@@@@@@@@@[email protected]&&&&&5J?J^    7B?~:....:^57^..      
@@@@@&&&&@@@@&&@#^   .!^ B&!^^J^^:JG.      :P&G~  .#&&&&&&##&#J:.:Y&@@@@@@&^.^[email protected]@@@&&&&#55PJ. .  ~7!7~!!~^~5Y!:..      
@@@&&&&@@@@@&@&J.        :B?.. .:^?.     :JP?.   !&&&&&#GY55!..~PBPJ&@@@#@@J    #@@@@&&&GGBG~^^7  .      .:~7~:.        
@@@&&@&#@@@&@B:            ::....:    .^!~.   .!B&&#BPJ7?7^ .:^^.  [email protected][email protected]!   [email protected]&[email protected]@&BGP&#?7~P!  .                     
@&&&@[email protected]@@@&?.                      ...   .:!P##GYJ7~~~:.          5?^:~!7!   ^&Y~PPYY5P&&5YJG#: ^:                     
&&@&[email protected]@@@B:                            ..:::.....                 :^...:.   .Y^^55JYYP&&GP5#@G^:J.                     
&@B~~&@@@5.                                                                ..:.JGJJJYB&&GGP#@@#?G!                      
@#7^[email protected]@@?                                                                     ~BJJJ5&&#GGG&@@@#BB:.                     
&[email protected]@@7                                                                     .P5JYB&&BGG#@&&@@B&Y:.                     
&[email protected]@J~.                                                                   ^PPPB&&#BB#@@@&[email protected]#GY7~.                   
@@[email protected]@5  ::.                                                              :75BB#&&##&@@@@@&#[email protected]!77~:                
@@@@@&J^.~?.                                                           .^!?&##&&@@@@@&&@&[email protected]~777Y:  .^7~.             
@@@@@@@@@@@#^                                                             [email protected]@@@@@@@@&#[email protected]&##&&PJ!7!7!     YP7.           
@@@@@@@@@@@@&^                                                           :@@@@@@@@@@&#[email protected]@&&G?7!!!!!!    :??YPJ:         
@@@@@@@@@@@@@&:                        ^JPBB#####BBGG5J!^.              :#@@@@@@@@@&&&.^&#Y?77!~!!!!   ~?!~^~JB5^       
@@@@@@@@@@@@@@B.                      .GJJJJJ55GB#&&&&&&@@B            [email protected]@@@@@@@@@@#~:5GJ7!7!!~!. :JJ7~^:::^75Y^.    
@@@@@@@@@@&@&@@P^.                     ?J!~~~~^~~!7J5B#&&@5          [email protected]@@@@@@@@@@@&5#@P??777?~JPY77!~^:....~J?:   
@@@@@@@@&&&&&@@&Y!^:                    ?J!!~~~~~^^~~~!YG7          !BP7~!~^&@@@@@@@@@@@@@&@@&Y?JY5YJ7!!!~^::......!J:  
@@@@@@@&&&&&&&@&Y!~~!!:                  :!7!!~~~~~~~~~:          !BGJ!!!!!~&@@@@@@@@@@@@&&##&&BJ!~~~^^^^^^:.....   ^P^ 
@&&&&&&&&&&&##@&5!~^^~JP?.                  :^~~~~~^:.          ?#BY?7!!~7^[email protected]@@[email protected]@@@@@&@@@#GGGB#B5J?77~^:::.....    ~B:
&&&&@@@&&&#BB#@#J!~^^^^~5#B!.                                .Y&BY7?7!~~!^:&@@@##@@@@@&&&&@@&#GBGGGB#PJ!^:........    7G
@&&#&&&&##[email protected]@G7!~^^^^:^~5#&G!                            :5&[email protected]@@@@@@&&@@@@@&&&&@@&#BBBGGBPJ!~^:.......    7
@@&&#BBBGGPG&@&J!~^^:::::::~?G&&G!.                      !B&GJ7777!7?JJ5Y5#@&G&@@&BB&@@@@@@&&#&&#BBGBBB&&!^~~^:........ 
@@@&&#BBBB#&@@G7!^:::::^::^^^^~JG&@B?.                .J&&GJJJ777!!!!!77?YY7!?Y&@#G55P#@@@@@@&&&###BGB#B#G.  .::^:......
.?#@@@@@@@@@@#Y7!~:::::::^^^^^^^^~7P&@&P~.          ^5#B5J???????777777!!~^^^~!JB#B5Y?7?5G&@@@@@@&&&#BBGBBY      .:^:...
!^^?5B#BP&@@@57!^^:.::..:::^:::::::::~?G&&#P7^. .^J##PJ777!!!!777!!!!~~~~~^~^^^!YG#BG5JJ?!!7JG#@@@@@&GPPYY?     :^:.:~!~
@@@@@@@@@@@@@#Y~^::......:.::::::.:.....:~JP&@@@@@B5J777!!!!!!!!!!~!~~~~^^^^^^^^~YBBB###B55P555PGB##J^...        .!J??J7
@@@@@@@@@@@@@@@B?^:::.........::.............&@@#GJ??77!!77777!!!!!!~~~~~~~^^^^^^:!PGP5557~::^:^^^^:^^^.           .~?~^
@@@@@#[email protected]@@@@@@#J^:[email protected]@&GPPYJJ77777777?777!!!!~~~~~^^^^^^:^~?YYYYYY7!^..      .~:           J7^
7!:..      [email protected]@@@@@@G!:................ ......#@@&BP5JJ?77??7????????777!!~~~^^^^^^^^^^~!!77??J??J?77!!!!!!:         JY7
             :[email protected]@@@@@@&Y~:............     [email protected]@@&&BPGGPPBGGGGB&&@@@@&&###BP5?7~^^^^^^^^^^~^^^^^^^^^:::::^^.       YP7
               ^&@@@@@@@@&P!:.....              :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GY7~^^^^::::::::::::.....:::     .G5?
                 [email protected]@@@@@@@@@&5~.                   [email protected]@@@@@@@@@@@@@@@@@@&B5?7!!JG&&&&&&#GY!^::::::::::..........:   :GG57
                   [email protected]@@@@@@@@@&5~.                ^@@@@@@@&&@&&&#BGY7^..       .^?P##BB#&#5!^:^:::::::.........:  GGY7!
                     .!P&@@@@@@@@@&P~.             [email protected]@@@@@P  .                      .^JPG5YG#&BPJ7!~^^^:::........75?!!~
                         :?G&@@@@@@@@&B?:          [email protected]@@@@@~                   ..        .:^..:JB&&&BY7!~^^^:::...^Y7~^^^
                             .~JB&@@@@@@@&BJ~.     #@@@@@&.                    :.                :JG#&#PY7!~^::.:7~^^:::
                                  .7G&@@@@@@@@#[email protected]@@@@@B                      ::            ..   .~?P&@&#PJ7!~~^::::::
                                      :75B&@@@@@@@@@@@@@@B                       .~:                .^:^7P#&&##G55?!!^::
                                           ..~!JPG&&&&GJ5G^                       .!^                 ^:.   .....^^7Y5GP
                                                                                    !7.                .^:.           :7
                                          :.                                         :?^                 .::..          
                                        [email protected]@@P.                                         !7.                              
                                     7#@PY&@@@P.                                        .!^                             
                                   ~GB&@@@[email protected]@@@J                                         .^:.                       .:.
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}