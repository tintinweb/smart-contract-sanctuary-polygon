// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

// ####BPPG#&&&&############BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5
// ##BPYP5YGGGBBB#######BBGGGGGBGPPPPPGPPPPPPPPPPPPPPPPPPPPPPPPPGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555555555555555555555555555555555555PPPPPPPPPPPPPPPPP5
// BBG?J#GP&B5G#@@@@@@@@@@@@@@@@&BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5PPPPPPPPPPPPPPPPPPPPP5YYYJYYYYJJJJJJJJJJJJJJYYYYYYYYYYY555555555YYYYY55PPPPP5
// &&B?Y##B##BYB#&@@@@@@@@@@@@@@@@&BGPPPPPPPPPPPPPPPPPPB#PPP5555555YYY55PPP55555555PGGBBGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55YJJPPPP5
// &&B?Y###&#B5PBGG#@@@@@@@@@@@@@@@@&BGPPPPPPPPPPPPPPPPGG5555555555YYYJJJJJJJJ?JJJ????JYPBBPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGPPPPPPPPPPPPPPPPP5?YPPP5
// #&B?5#BB##B5Y5PP5G#@@@@@@@@@@@&&&&@&BGPPPPPPPPPPGGPP5YYJJJJJJJJJJJJJ????JJ?77JJJJJJJ???YBBPPPPPPPPPPPPPPPPPGPPP5PPPPPPPPPPPPGGPPPPPPPPPPPPPPPPP5??5PP5
// ~!P?5BBB##BBBYJ5PPB5B&@@&&@@@@@@@@@@@@#GPPPPPPPB5JJJJJJ????????JJJ?7777?JJJ??JJJJJJJJJJ7?GBPPPPPPPPPPPPPPPPPPP5PPPPPPPPPPPPPPPPP5PPPPGBPPPPPPPPJJY5PP5
// #7.!G&####BYG&BYYYP55B#&@@@@@@@@@@@@@@@@#GPPPPBY?JJJJJJ???????JJJJJ?????JJJJJJJJJJJJJJJJ?7PBPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGP?Y55PP5
// PY???JP#@#B5PPGBBPYJ5PGGB&@@@@@@@@@@@@@@@@#GG#YJJJJJJJJJJ???JJJJJJ???????JJJJJJJJYJJYJJJ55?5GPPPPPPPPPPPPPPPP5PPPPPGBPPPPPPPPPPPPPPPPPPPPPPPPBG?555PP5
// !!!????!Y&&BGBGP5B#GYY5PPPG&@@@@@@@@@@@@@@&B#GP5YYJJJJJJJJJJJJJJJJJJ?JJJJYYJJJJJJYYYYY5PPPPYPGPPPPPPPPPPPPPP5PPPPPPPPPPPPPPPPPP5PPPPPPPPPPPPPPY?555PP5
// ^^^!???P?~Y&&###BP5G#PJY5P5PP#@@@@@@@@@@@@###BGGPPP55YYJJJ?JJJJJJYYYJJJJJYJ????JJJJY5PPPPPB#GGYPPPPPPPPPPP555PPPPPPPPPPPPPPPPPP5PPPPPPPPPPPPPPY?555PP5
// ^^^!??~^?5J~5&&###BG5GBPYY5P55G&@@@@@@@@@&######BBGGGPP5PP555YYY555PYYYYYJ?JYY5P5JJ555PPPB####Y7?????????JJ?????????77??????YJ?????????77????????????7
// ^^^!??~^^^55!!J#&&###55GBB#5Y5PGG#@@@@@@@@&&#######B#BBGGBGPPPGGP5PPGGGY7!!JPGP5YYJYYYPPP####&G??J?JJ???YGGY??????J?~~7J???JGGJ?J????J?~!????J??J??JJ?
// ^^^!?7^^^^^!?PJ!?#&###GP5G#BYJ5PP5G#@@@@@&&@&######BB###B#GPPPBBG5555?YJ??J?YP?!!?YJJJGGG####&#J??J??JJ????????????JJJJ?????????J?????JJJ???J???J??JJ?
// J7^~??^^^^^::^75Y!J#&#[email protected]@@&@@@&######B###GGB#GPGGPPPP5J?JPPG5J55YY5P5PPGBB#####&YJ?J??J???????????????????????J??J????5BJ????J???77JJJ?
// :?5J??^^^^^^:.:^75J7?G&####G5PBB5JY5P55B&&&@@@&#####B###BGB##BPPPPP55P5YYY5JJ75GPPPPPPPGB#####&BY??JJ????????????????????????J??J????JYJ????J??????JJ?
// ^::7???^^^^!!~:.!GJ5Y~7P&&BGYP5P#BG#B5PBB&&@@@@#####B####B#####GPPYJ5PP5Y555YJ5GPPPPPPG#######&&#Y7!7J??????????????????????????J???????????J??????JJ?
// ??!^??5P!^^!!!!~~!::?5Y77G&#GG#G5PB&PJYP5&&&@@@&####B#####B######GGPPPPP55Y5PGPPPPPPPG########&&&B??????????????????????J???????J?????????????J????JJ?
// 777???^^Y5~!!!!!!!^..^~J5?7G&#B##BP5GB5YYB&&&@@@####B#####B########BGPPPPPPPP5GGPPPPG#########&&&&P7?J??????????????JJJ?????????J?????????????J????JJ?
// 7777??7~.!557!!!7P7!^.::~YY?7YB##B#[email protected]&&&&&&####################BBGPPPPPY5GPGGB##BBBBBBB#&&&&#Y7J????????????????????????J????????JJ????J?????JJ?
// 7777????7~:!JPY7!!!!JY^:.!YJP7~JB&#&[email protected]&&@@@&#######################BBGGPPPPPPPPPP55GBBB#&##&@&G7?J?JJ?????????YJ???????5Y??J??????77J??J??????JJ?
// 777?????7?7!!^7GJ!!!JJ!!~?Y:~Y5J!J#&B5#B5P&&#&&@@&###########BBBBBGGPPPPP55555555555555GBBBB#&##&@&#J7??????JJYY55P#GPPPPP5YPY!?JJJJJJJ7?JJJJ??????JJ?
// 777?????7777?7^^?PJ!!!!!!!~:.:^?PJ~?#&##[email protected]&&@&&&&#&&&&&&#&###BBBBBBGP555555555555555PGBBBB#&###&@@&B7?Y5PGGGPP555P55PP5YY5G#BGJ?JJJJJJJJ?JJJ??????JJ?
// 7?77???7777777?7^^JPY!!!!!!!~:.:^!YY!JB&#[email protected]&@@@@@@@&&&&##&&&&&##BBBBBBGPP55555555555PBBBBBB#&###&&@&&####BBBGPPPP5PPPGGGGPYY##P^^^^^^^^^^^^^^~?!!?~^^^
// .^!7?777J?7?77?5PJ~:JPJ?!!^^~!~:::^7Y5!?B#@&@&@@@@@@@@@&#####&&&#BBBBBBBBGGPPPPPPPGBBBBBBBB&&&&&&&@@@@#GGGGGGBBB#BGGGPPPPBBB57:::::::~7::::::~?~~?^:::
// ?..:!7??5?7~77?PPP?~~^!PP!:^^~!!~^.:^!YY7?B&&&@@@@@@&&&&&######&&##BBBBBBGBBBBBBBBBBBBBBBB#######&&&&&&&&####GP5YY5PPGPP5J!^!Y::^::::!?::::::~?~!?~:::
// ^.~^.~!7777!7!!7?57??7~^75P7^!!!!!~::^!JBPB&@@@@@&&&&&@@@&&&&##&#&&#BBBBBGBBBBBBBBBBBBB#####&&&@@@@&#BGPYJJJJJY55JJ7~~^::::::^:::::::::::::::~?^!?^:::
//    :~?::~J?777777J77!777~:!5J77?J5PGGBB#BB&&@@@&@@@@@@@@@@&&&&##&#####BBBGBB####&&&&@@@&&@@&##BP5J??77?J5P5YJ7~^:::::::::::::::::::::::::::::~?^!?^:::
//     ^?!^.:~7?7777!!777?JJYJY#BBBBBBBBBBB##&&@@@@@@@@@@@@&&&&###B#####&&&&#&&&&&&&##BBGP5YJJ?7??JJYYPB#&Y~^::::::::::::::::::::::::::::::::::::?~!?^:::
// ^   ^7 ?B~.^7???77~^5GGBBBBBBGBBBBBBB#&&&&&&&&&&&####[email protected]@G:::::::::::::::::::::!7::::::::::::::^^^:!?^:::
//     ~7 .: .^^^!?JP?J###BBBBBBBBBBBBBBBBBBBGGPPP555YYYYJJJJJJ?????77777??JJ5PGGGGP5Y55YYJJ7     ^[email protected]@G::::::::::::::::::::::::::::::::::::^~^::^7^:::
//     !!      :^^^J&J7JP#&&&&&&&##BGGPPPP5YYJJJJJJ?????77777!!7?77??JYY555YJ?!~^:....??????7     [email protected]&Y^::::::::::::::::::::::::::::::::::::::7??7::::
//     !~  :.    .^::!777?JJJJJJJJJJJJJJ?J5Y?????YP5??~^^~~!!7?75J~~~::..   .     .  .??????7      :[email protected]#::::::^::^^:::::::::::::::::::::::::::::7??!::::
//     7: .Y^     :~: .~7?7777!777777777!^[email protected]??:7??7!^77 :?.         .    .    7?????7       [email protected]::::::::::::::::::::::::::::::::::::::::!??~::::
//     .          . . .^!~7777?777!!7777?7~:[email protected]@B7!7&&&@@@@@#B#GYJ7^:    .   ..   .??????7       ^[email protected]#^:::::::::::::::::::::::::::::::::::::::~?7:::::
//    :!               .J.~?77777?7^777777??:^B77&@&?: ...:^?5PGGB#&&@@&BY7:.   .    ^???????...     !#@&!!!!!~!~!!!!!!!77!!!!!!!~!~!!7!~!7!777!~7J?!!!!!
//    ^?             .:^^~7777777!!77?Y??7!:~GJ7?&@#:       !??77??!.^!7J#@&!   .    .??5G7:!YJ  : .~7#@@#GP5Y5B&BPBBPP5P5GBGBG5GBB#&#B#BB#GPGGBGP5GGPGBG
//    ^?.          .^^^~7?77777!!77777J?~::JG?!?J&@#.   ..  :?57!??~     .P&#^   .  . :J&&GP#@!:PJ  7J&@@@PG5G##G5PPPG555G5GBPBGY5BG#&BPG#5PPY5YYPGPJGG#P
//    ^?.        .^^:7???7777!!7!777?7~^[email protected]@#^ ..  !P&@@@@#5:  ..  :&&J   ...  ?&@@@@@@@@Y  .7?#@#@@&#GPGGGGBGPPPYGPGBGGG55BBBBBGBG5PP5555P5J5GGBP
//    ~?:      :^^^!?Y?7777!!777!7?7^~YYY77!!!J&@@@@7.   [email protected]@@#G&@@@G^  ..  #@5       [email protected]@@@5Y&@@@[email protected][email protected]@@5PPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGJ?5PPPP
//    ~?:    :^^^!7?77777!!7777??7^^[email protected]@&@@5:  [email protected]@@B7:[email protected]@@@B   .  [email protected] [email protected]@@G ~&@@@@7:[email protected]:[email protected]@&YPPPPPPPPGBPPPPPPPPPP5PPPPPPPPPPPPPPPJ?5PPPP
//    !?^ .^^:^!??7?J7!!77777?7!^:?B?!?7!!!!~7&@[email protected]#G7 .#@@@[email protected]@@@&.  .  [email protected]   ..  [email protected]@@P:[email protected]@@@&JJJ??#B^&@@B?5PPPPYP5PGY5PGGGPPPP5PPBPGGGGBBGBBPGY?YGP55
//    7?~^:..~7?777?Y777777?7!:~?5P7!!Y7!!^:[email protected]@[email protected]&B?^ [email protected]@@&[email protected]@@@@7  .   [email protected]    .. [email protected]@@@#@@@@Y^::^??&P^@@@P?YYP55JGGB#YY#BB#PPPYJPGY5#B#GP&@B55B5?5BBJ?
//    7?!:.77?77777!77!77?7!^~5P?!!!!!!~~..:^7&@B^B&&J~  [email protected]@@@@@#G7  ..   [email protected]      .JG#@@&BY^  . ~?J&[email protected]@@P?JPPPPP555PPPGGBGPPPPPPPP555GBBGGBBBGJ?5P5P5
//  .^??^~??7777!!77777?7~:75Y?!!!!!!~:.^:^^[email protected]@[email protected]@5^ .  !5PP57:   ..    [email protected]&:       !77JJ?.      [email protected][email protected]@@Y?5PPPPPGPPPPPPPPPPPPPPPPPPPP555PPPPPGJ?PBGPP
// ~~^?????JJ?!!777777!~:755!!!!!!!~:.:^^^7YG&PP&&&@@5^    :?????!. ..     [email protected]&:       :?????.      !?Y#@&&#B5GGPP5555PPPPPPGGBGPGGGGGGBGBYJJPPGP55J?G&&P5
// .:!??77YBBY77777?7:.^JG!!!!!!!~^..^^~7YG###&BPB#@@B^     7????!         ~&&^        ^^7??: .    !?G&#B5PG5B#[email protected]&YYP#G5BGBB#B#PP5#5P5BYBPYPJ?5PPYG
// !????777777777?7^:YYY?!!!!!!~:.::^~?PGB##B###[email protected]@@~     :????!         ^&&^          !??....   7?G#5PPYY55P5Y5PPGGG5Y5PY555G55PG5P5PBPJPG5PPGG??PGPPP
// ?????7777777?7^~7PY!!!!!!!^:.:^^~?5B##B####BPJJ5&@@J      .???:         :@@?       .. ~?~ . .  .?J&#B#####B##BB####BB#B#############B#BB####B#G??B###G
// 7????7777?7!^:YP?!!!!!!!~:.:^^~?P#&#B####BPJJY5PB&@#.      :!~ .       ..?Y^      .   ~?..  .. :[email protected]########BB################B####B&&#######P?JB###B
// 7????77?7^.:~5P!!55?!!~^::?!:75B&#&&#GBB5JYBBYYG#&@@7         . .     .          ..^  .: .   . [email protected]&#BB######BBBB#####BB#####&&BB#####@@BB#####P?JBB##B
// 77????7^.7J55J!!!!7!::.::^~?5B###B###G5JY5PPPGG#&&@@B.         .~.    .   . ::  . :?.    .   ..?&####BBBBBB###BB##############BB#######BB#####5?5####B
// 77???^:^YP!!!!!!!~^..^^^~?PB#######B5JYPPPPPB#&@@##@@7   ...^^.?G!....YY...:?B7::.!B^.:.     .~G&B#####BBBBBBBB###############BB##############Y?P####B
// ??7??JPJ!^^!!!!~:.::^^~75B#B#####B5YY5P5PPG#&@@@@&[email protected]@#~  ^7PBBB#@BBBBB&@###B#@@##&&@&&#&?:   :G&B#############################BB#####BB#######5JG####B
// ~::??PG^^^^!!~^^..^~!JG##B####BG5JYBPJ5GB#&@@@@@@@&#&@G!  ~B&&&@@&#&&B&@&##BB&&[email protected]   .5&GG##########&#########BB#######BB##############Y?GB###B
// .!5???7^^^^~:.:::^J5G#######B5JY55PGP5B#&@@@@@@@@@&#[email protected]@B?: .:[email protected]::[email protected]:.YB . ^#!      ^[email protected]###################BB########B##############Y?BB###B
// Y?!?7^^^^^^::^^^!5G######BBPYJ5PPPPGB#@@@@@@@@@@@@&@@@@@&Y^    :P!     PJ    ^~   :J~    [email protected]&B################################B#####BB#######Y?B####B
// ^^~?7^^^^^^^^^~JG########PYJ5PPPPGB#@@@@@@@@@@@@@@@&&#&@@@B!.  .^.     ^. .  .    .!   .:[email protected]@####BB################BB######BBB#BB#####BB######5?G####B
// !^~?7^^^^^^^7YB##&####BPYYGGPPGBB&@@@@@@@@@@@@@@@@@###BB&@@@#Y~           .           .^[email protected]@########B####B############BB####&#BBB###BB####B###5?GBBB#B
// 7^~?!^^^^!?YB#######G5YYYP&&&##&@@@@@@@@@@@@@@@@&BPB#BBGGBB#@@@BJ^.       .          :!J#@&BB##BBBBBB#B########BBB########B###BBB#B#BB#B####B#P?BBB##B
// ^^~?!^^~75P#######B5J55PPPB&#&@@@@@@@@@@@@@@@@&BP5GGP555555PB#&B&@#57:            .^7YB&&#GGBBBGGGGGBBBBBBBBBBBBBBBGBBBBBBBGGBBGGBBBBBBBBBBBBB5JGBBBBG
// ^^~?!~JPBBB#####G5JJ5PPPPB#&@@@@@@@@@@@@@@@@&G5555555555PGGGP&@BYJY#@&#P5J?J7!?JY5GB&&&@#GBBBBBBBB#BBBBBBBBBBGBBBBBBBBBBBBBBBBBBGBBBBBBBBBBBBB5?PBBBBG
// ^^~?JG&G#BB###GYJJ5Y5PGG#&@@@@@@@@@@@@@@@@#BB55555555PPPBBG5J#@&J^ .:^?PGB#&&&&&&BPP7:[email protected]@&BBBBBBBB#BGBBBBBBBBGBBBBBBBGGBBBBBBBBBGBBBBBBBBBBBBBP?YBBBBG
// ~7Y?P##B#BBBPYJYY555BB#&@@@@@@@@@@@@@@@@#PGGG5555555G#[email protected]@5?~       ...:::..     :[email protected]@#BBBBBBBBGPGBBBBBBBBBBBBBBBGGB&BBBBBBBGBGPBBBBBBBBBBG?JBBBBG
// PGB?PB##&#BYJYPPPPGG#&&@@@@@@@@@@@@@@@#P55P555555PPGBGGGB#B&@@G??~                     [email protected]&#BGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGBBBBBBBBBBBBBG?JBBBBG
// GGP?P###&#B55PPPGB#@@@&@@@@@@@@@@@@@#P5555555Y5Y5PPPG#&&@@@@&P???~                     .?#@@@#BGGGBGPGBGBBBBBBBBBBBBBBBBBBBBBBBBGBBBBBBBBBBBBBGJJGBBBG
// BB5?P#B#@#BPPPGB#@@@@@&@@@@@@@@@@&#PYY5PGGGBBBBBBB#&@@@@&#B5J!^:^                       :5&@@@@&#GPPPGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB5?PBBBG
// GBP?5##&@@&BBB&@@@@@@&@@@@@@@@@@&B#BB#@@@@@@@@@@@@&&#GP5J?!^.                            .!YP&@@@@&#BBGP5Y55555PPPPPPPPGGGGGGGGGBBBBBBBBBBBBBBBG?YBBBG
// B#BGB###&&&#&@@@@@@@@&@@@@@&@@@@@@@@@&&&#BP5JYYYYJJ?7!~^:.                                   :!?YP#&@@@@@@@@@@@@&&&#BBBBBGGBBBBGGBBBBBBBBBBBBBBBYJBBBG
// ##########&@@@@@@@@@@&&&@@@@&#G5YYYJJJJ?77!!!~~^::..                                               :~7J5PGB###B55PPGB&&&@@@@@@@&#BGBBBBBBBBBBBBBBGBBBG
// BBBBBBBB#&@&&&&&&&&&@@@@@BPYJ?????7!~^:..                                                                  ...       ..:~!?J55G&@&GGGGGGGGGGGGGGGGGGGG


import "./Ownable.sol";
import "./Address.sol";
import "./SafeCast.sol";
import "./ERC721.sol";
import "./Treasury.sol";
import "./ERC2981.sol";

contract CryptoHatz is Ownable, ERC721, ERC2981 {
  using Address for address;
  using SafeCast for uint256;
  using Strings for uint256;

  // EVENTS ****************************************************
  event baseURISet(string _uri);

  // MEMBERS ****************************************************
  
  uint256 public immutable MAX_SUPPLY;

  // Number of currently supplied tokens
  uint256 public totalSupply = 0;

  string public baseURI;

  /* Mapping from owner to list of owned token IDs */
  mapping(address => mapping(uint256 => uint256)) public _ownedTokens;
  /* Mapping from token ID to index of the owner tokens list */
  mapping(uint256 => uint256) public _ownedTokensIndex;
  
  Treasury public royaltyRecipient;

  // CONSTRUCTOR **************************************************
  
  constructor(
    string memory _baseURI, 
    uint256 _MAX_SUPPLY
  )  
    ERC721("CryptoHatz by Boy George", "HATZ")
    {
    //Sets the max supply
    MAX_SUPPLY = _MAX_SUPPLY;

    baseURI = _baseURI;
    emit baseURISet(_baseURI);

    address[] memory royaltyPayees = new address[](1);

    royaltyPayees[0] = 0xaF019dE18D30c5e0c5e1596ebf81B793648B9356;

    uint256[] memory royaltyShares = new uint256[](1);
    royaltyShares[0] = 100;
    
    royaltyRecipient = new Treasury(royaltyPayees, royaltyShares);

    _setRoyalties(address(royaltyRecipient), 700); // 7% royalties

  }

  // PUBLIC METHODS ****************************************************

  /// @notice Gets an array of tokenIds owned by a wallet
  /// @param wallet wallet address to query contents for
  /// @return an array of tokenIds owned by wallett
  function tokensOwnedBy(address wallet)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      ownedTokenIds[i] = _ownedTokens[wallet][i];
    }

    return ownedTokenIds;
  }

  /// @inheritdoc ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  //Returns the number of remaining tokens available for mint
  function totalLeftToMint() view external returns(uint256){
    return MAX_SUPPLY - totalSupply;
  }

  /**
  Batch transfers NFTs to users
  @param to : Array of to addresses
  @param tokenIds : Array of corresponding token ids
  @return true if batch transfer succeeds
  */
  function batchTransfer(address[] memory to, uint256[] memory tokenIds) external returns(bool){

    require(to.length > 0, "Minimum one entry");
    require(to.length == tokenIds.length, "Unequal length of to addresses and number of tokens");
    require(tokenIds.length <= balanceOf(msg.sender),"Not enough tokens owned");
    
    for(uint256 i = 0; i < to.length; i++){
      safeTransferFrom(
        msg.sender,
        to[i],
        tokenIds[i]
    );
    }
    return true;
  }

  // Lets owner of token to burn it
  function burn(uint256 tokenId) external {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner and not approved by owner");
    _burn(tokenId);
  }

  // OWNER METHODS *********************************************************

  /// @notice Allows the contract owner to mint NFTs to a user
  /// @param to address for the reserved NFTs to be minted to
  /// @param numberOfTokens number of NFTs to reserve
  function mint(address to, uint256 numberOfTokens) public onlyOwner {
      
    require(numberOfTokens > 0, "Minimum one token");
    require((totalSupply + numberOfTokens) <= MAX_SUPPLY, "Exceeds max supply limit");

    uint256 newId = totalSupply;

    for (uint256 i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }
    totalSupply = newId;
  }

  /// @notice Allows the contract owner to mint NFTs to CryptoQueenz holders or team members or promotional purposes
  /// @param to address for the reserved NFTs to be minted to
  /// @param numberOfTokens number of NFTs to reserve
  function bulkMint(address[] memory to, uint256[] memory numberOfTokens) external onlyOwner {
    require(to.length > 0, "Minimum one entry");
    require(to.length == numberOfTokens.length, "Unequal length of to addresses and number of tokens");
    
    uint256 totalNumber;
    uint256 i;

    for(i = 0; i < numberOfTokens.length; i++){
      totalNumber += numberOfTokens[i];
    }

    require((totalSupply + totalNumber) <= MAX_SUPPLY,"Exceeds max supply limit");
    
    for(i = 0; i < to.length; i++){
      mint(to[i], numberOfTokens[i]);
    }
  }

  /**
  @param tokenId : The token id
  Fetches the token URI of token id = tokenId. It will return dummy URI if the base URI has not been set.
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json") ) : '';
  }

  // PRIVATE/INTERNAL METHODS ****************************************************

  // ************************************************************************************************************************
  // The following methods are borrowed from OpenZeppelin's ERC721Enumerable contract, to make it easier to query a wallet's
  // contents without incurring the extra storage gas costs of the full ERC721Enumerable extension
  // ************************************************************************************************************************

  /**
   * @dev Private function to add a token to ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != address(0)) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to != address(0)) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }
}