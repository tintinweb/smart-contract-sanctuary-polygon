// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./IDexGoNFT.sol";
import "./IDexGoStorage.sol";
import "./IDexGoRentAndKm.sol";
import "./IHandshakeLevels.sol";


contract DexGo is Ownable,IERC721Receiver {
    using SafeMath for uint256;

    address public storageContract;
    function setStorageContract(address _storageContract) public onlyOwner {
        storageContract = _storageContract;
    }
    function getStorageContract() public view returns (address) {
        return storageContract;
    }
    constructor(address _storageContract) {
        storageContract =_storageContract;
    }

    // shoes:
    uint8 public constant SHOES0 = 0;
    uint8 public constant SHOES1 = 1;
    uint8 public constant SHOES2 = 2;
    uint8 public constant SHOES3 = 3;
    uint8 public constant SHOES4 = 4;
    uint8 public constant SHOES5 = 5;
    uint8 public constant SHOES6 = 6;
    uint8 public constant SHOES7 = 7;
    uint8 public constant SHOES8 = 8;
    uint8 public constant SHOES9 = 9;
    uint8 public constant MAGIC_BOX = 10;

    uint8 public constant PATH = 100;
    uint8 public constant MOVIE = 200;

    uint256 balanceOfPaths;
    mapping(uint256 => address) public pathsOwners;
    struct Approval {
        uint256 shoesTokenId;
        address sender;
        uint256 pathTokenId;
        string socialPostURL;
    }
    /*Лидер мнений или обычный игрок(прошедший более 2-х маршрутов сам) разрабатывает и открывает другим пользователям маршруты
    лидером мнений по одному, с максимальным выпуском трасс в 20 штук для одного лидера
    % распределения вознаграждения для каждого отрезка пути и для каждой остановки (в сумме 100%)
    Стартовая цена создания маршрута составляет 50 долларов. Однако каждая новая создание увеличивает ее цену на 10% для этого лидера мнений.
    После имплементации маршрута в систему командой проекта, лидер мнений должен купить обувь и пройти маршрут сам.
    С этого момента маршрут активируется и доступен в системе для любого игрока, который купил обувь.
    Чтобы лидеры мнений активнее привлекали игроков к соревнованиям на своих маршрутах и тем самым развивали игровую экономику,
    в dexGo предусмотрен максимальный период простоя маршрута. Если никто не проходит маршрут в течении 90 дней,
    он деактивируется и не может более использоваться в системе.
    Дата создания маршрута влияет на максимальный период простоя и на распределение доходов.
    Чем раньше созданы маршруты, тем больше получает лидер мнений и тем больше у него максимальный период простоя.
    */
    Approval[] public approvalsAddPathStack;
    event RegisterAddPath(uint256 indexed tokenId);
    function registerAddPath(uint256 tokenId, uint kmWei) public payable nonReentrant {
        require(msg.value >= IDexGoStorage(storageContract).getFixedPathApprovalAmount().sub(IDexGoStorage(storageContract).getValueDecrease()), "WV");

        require(!IDexGoStorage(storageContract).getInAppPurchaseBlackListWallet(msg.sender) && !IDexGoStorage(storageContract).getInAppPurchaseBlackListTokenId(tokenId), "BL");
        require(IDexGoStorage(storageContract).getTypeForId(tokenId) == PATH, "WT");
        IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).approveMainContract(address(this), tokenId);
        IERC721(IDexGoStorage(storageContract).getNftContract()).safeTransferFrom(msg.sender, address(this), tokenId);
        IDexGoStorage(storageContract).setKmForPath(tokenId, kmWei);
        pathsOwners[tokenId] = msg.sender;
        balanceOfPaths++;
        emit RegisterAddPath(tokenId);
        approvalsAddPathStack.push(Approval(type(uint256).max, msg.sender, tokenId, ""));
    }
    mapping(uint256 => uint256) public pathsApproved;
    uint256 pathsApprovedCount;
    function setPathApproved(uint pathTokenId, bool approved) public {
        require(msg.sender == IDexGoStorage(storageContract).getAccountTeam1() || msg.sender == IDexGoStorage(storageContract).getAccountTeam2() || msg.sender == owner() || msg.sender == IDexGoStorage(storageContract).getGameServer(),'OA');
        require(IDexGoStorage(storageContract).getTypeForId(pathTokenId) == PATH, "WT");
        require(pathsOwners[pathTokenId] != address (0), "PnA");
        require(IDexGoStorage(storageContract).getKmForPath(pathTokenId) > 0.0005 ether, "WK"); // TODO - temporary low price
        pathsApproved[pathsApprovedCount] = pathTokenId;
        if (approved) pathsApprovedCount++;
        else pathsApprovedCount--;
    }
    function getPathsApproved() public view returns (uint256[] memory) {
        uint256 [] memory result = new uint256 [](pathsApprovedCount);

        for(uint256 x=0;x<pathsApprovedCount;x++) {
            result[x] = pathsApproved[x];
        }
        return result;
    }
    function isPathApproved(uint pathTokenId) public view returns (bool) {
        for(uint256 x=0;x<pathsApprovedCount;x++) {
            if (pathsApproved[x] == pathTokenId) {
                return true;
            }
        }
        return false;
    }


    Approval[] public approvalsReturnPathStack;
    event RegisterReturnPath(uint256 indexed tokenId);
    function registerReturnPath(uint256 tokenId) public nonReentrant {
        require(!IDexGoStorage(storageContract).getInAppPurchaseBlackListWallet(msg.sender) && !IDexGoStorage(storageContract).getInAppPurchaseBlackListTokenId(tokenId), "BL");
        require(msg.sender == pathsOwners[tokenId], "NO");
        require(IDexGoStorage(storageContract).getTypeForId(tokenId) == PATH, "WT");

        emit RegisterReturnPath(tokenId);
        approvalsReturnPathStack.push(Approval(type(uint256).max, msg.sender, tokenId, ""));
    }
    function approveReturnPath(uint pathTokenId) public nonReentrant {
        require(msg.sender == IDexGoStorage(storageContract).getAccountTeam1() || msg.sender == IDexGoStorage(storageContract).getAccountTeam2() || msg.sender == owner() || msg.sender == IDexGoStorage(storageContract).getGameServer(),'OA');
        require(IDexGoStorage(storageContract).getTypeForId(pathTokenId) == PATH, "WT");
        require(pathsOwners[pathTokenId] != address (0), "PnA");

        for(uint256 x=0;x<pathsApprovedCount;x++) {
            if (pathsApproved[x] == pathTokenId) {
                pathsApproved[x] = 0;
                pathsApprovedCount--;
                break;
            }
        }

        for(uint256 x=0;x<approvalsReturnPathStack.length;x++) {
            if (approvalsReturnPathStack[x].pathTokenId == pathTokenId) {
                delete approvalsReturnPathStack[x];
                break;
            }
        }
        IERC721(IDexGoStorage(storageContract).getNftContract()).safeTransferFrom(address(this), msg.sender , pathTokenId);
        balanceOfPaths--;
        delete pathsOwners[pathTokenId];
    }

    mapping(uint256 =>  mapping(uint256 => uint256)) public completedCountTotal;  //[pathID][shoesID]
    function getCompletedCountTotal(uint256 pathTokenId, uint256 shoesTokenId) public view returns (uint256) {
        return completedCountTotal[pathTokenId][shoesTokenId];
    }
    mapping(uint256 =>  mapping(uint256 => mapping(uint256 => uint256))) public completedCountMonth;  // [pathID][shoesID][yearMonth]
    function getCompletedCountMonth(uint256 pathTokenId, uint256 shoesTokenId, uint256 yearPlusMonth) public view returns (uint256) {
        return completedCountMonth[pathTokenId][shoesTokenId][yearPlusMonth];
    }

    Approval[] public approvalsPathCompletedStack;
    event RegisterApprovalForPathCompleted(uint256 indexed shoesTokenId, uint256 indexed pathTokenId, string socialPostURL);
    function registerApprovalForPathCompleted(uint256 shoesTokenId, uint256 pathTokenId, string memory socialPostURL) public payable nonReentrant {
        require(!IDexGoStorage(storageContract).getInAppPurchaseBlackListWallet(msg.sender) &&
        !IDexGoStorage(storageContract).getInAppPurchaseBlackListTokenId(shoesTokenId) , "BL");
        require(msg.value >= IDexGoStorage(storageContract).getFixedApprovalAmount().sub(IDexGoStorage(storageContract).getValueDecrease()), "WV");
        require(pathsOwners[pathTokenId] != address (0), "PnA");
        require(IDexGoStorage(storageContract).getTypeForId(shoesTokenId) < 10, "WST");
        require(IDexGoStorage(storageContract).getTypeForId(pathTokenId) == PATH, "WPT");
        require(isPathApproved(pathTokenId) == true, "PnA");
        require(IDexGoStorage(storageContract).getKmLeavesForId(shoesTokenId) > IDexGoStorage(storageContract).getKmForPath(pathTokenId), "KM");

        Address.sendValue(payable(IDexGoStorage(storageContract).getHandshakeLevels()), IDexGoStorage(storageContract).getFixedApprovalAmount());
        IHandshakeLevels(IDexGoStorage(storageContract).getHandshakeLevels()).distributeMoney(msg.sender, IDexGoStorage(storageContract).getFixedApprovalAmount(), false, address(0));
        IDexGoStorage(storageContract).setKmForId(shoesTokenId, IDexGoStorage(storageContract).getKmLeavesForId(shoesTokenId) - IDexGoStorage(storageContract).getKmForPath(pathTokenId));
        emit RegisterApprovalForPathCompleted(shoesTokenId, pathTokenId, socialPostURL);
        approvalsPathCompletedStack.push(Approval(shoesTokenId, msg.sender, pathTokenId, socialPostURL));
    }

    function _distributeApprovePath(
        uint256 shoesTokenId,
        uint256 pathTokenId,
        uint256 shoesOwnerValue,
        uint256 shoesOwnerValueUSDT,
        uint256 pathOwnerValue,
        uint256 pathOwnerValueUSDT
    ) private {
        (bool rentable, uint percentInWei, address borrower) = IDexGoRentAndKm(IDexGoStorage(storageContract).getRentAndKm()).rentParameters(shoesTokenId);
        if (rentable) {
            uint256 borrowerValue = shoesOwnerValue * percentInWei / 1 ether;
            if (borrowerValue > 0) {
                Address.sendValue(payable(borrower), borrowerValue);
                Address.sendValue(payable(IERC721(IDexGoStorage(storageContract).getNftContract()).ownerOf(shoesTokenId)), shoesOwnerValue - borrowerValue);
            }
            uint256 borrowerValueUSDT = shoesOwnerValueUSDT * percentInWei / 1 ether;
            if (borrowerValueUSDT > 0) require(IERC20(IDexGoStorage(storageContract).getUSDT()).transfer(borrower, borrowerValueUSDT) == true,"WT");
            if (shoesOwnerValueUSDT - borrowerValueUSDT > 0) IERC20(IDexGoStorage(storageContract).getUSDT()).transfer(IERC721(IDexGoStorage(storageContract).getNftContract()).ownerOf(shoesTokenId), shoesOwnerValueUSDT - borrowerValueUSDT);
            emit ApprovedForPathCompleted(
                shoesTokenId, pathTokenId,
                shoesOwnerValue - borrowerValue, pathOwnerValue, borrowerValue,
                shoesOwnerValueUSDT - borrowerValueUSDT, pathOwnerValueUSDT, borrowerValueUSDT,
                borrower);
        } else {
            if (shoesOwnerValue > 0) Address.sendValue(payable(IERC721(IDexGoStorage(storageContract).getNftContract()).ownerOf(shoesTokenId)), shoesOwnerValue);
            if (shoesOwnerValueUSDT > 0) require(IERC20(IDexGoStorage(storageContract).getUSDT()).transfer(IERC721(IDexGoStorage(storageContract).getNftContract()).ownerOf(shoesTokenId), shoesOwnerValueUSDT) == true,"WT");
            emit ApprovedForPathCompleted(shoesTokenId, pathTokenId,
                shoesOwnerValue, pathOwnerValue, 0,
                shoesOwnerValueUSDT, pathOwnerValueUSDT, 0, borrower);
        }
    }
    event ApprovedForPathCompleted(uint256 shoesTokenId, uint256 pathTokenId, uint256 rewardShoesOwner, uint256 rewardPathOwner, uint256 rewardShoesBorrower, uint256 rewardShoesOwnerUSDT, uint256 rewardPathOwnerUSDT, uint256 rewardShoesBorrowerUSDT, address borrower);
    function approvePathCompleted(uint256 shoesTokenId, uint256 pathTokenId, uint16 completedResultInPercents) public nonReentrant {
        require(msg.sender == IDexGoStorage(storageContract).getAccountTeam1() || msg.sender == IDexGoStorage(storageContract).getAccountTeam2() || msg.sender == owner() || msg.sender == IDexGoStorage(storageContract).getGameServer(),'OA');
        require(IDexGoStorage(storageContract).getTypeForId(pathTokenId) == PATH, "WT");
        require(pathsOwners[pathTokenId] != address (0), "PnA");

        for(uint256 x=0;x<approvalsPathCompletedStack.length;x++) {
            if (approvalsPathCompletedStack[x].pathTokenId == pathTokenId && approvalsPathCompletedStack[x].shoesTokenId == shoesTokenId) {
              // match approval stack
                require(
                    !IDexGoStorage(storageContract).getInAppPurchaseBlackListWallet(approvalsPathCompletedStack[x].sender) &&
                !IDexGoStorage(storageContract).getInAppPurchaseBlackListTokenId(approvalsPathCompletedStack[x].shoesTokenId) &&
                !IDexGoStorage(storageContract).getInAppPurchaseBlackListTokenId(approvalsPathCompletedStack[x].pathTokenId)
                , "BL");
                delete approvalsPathCompletedStack[x];
                completedCountTotal[pathTokenId][shoesTokenId]++;
                uint256 month = BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp);
                uint256 year = BokkyPooBahsDateTimeLibrary.getYear(block.timestamp);
                completedCountMonth[pathTokenId][shoesTokenId][year * 100 + month]++;
                // path owner - 30%, shoes owner - 70%
                uint256 rewardForPathCompletedResult;
                uint256 rewardForPathCompletedResultUSDT;
                (rewardForPathCompletedResult, rewardForPathCompletedResultUSDT) = IDexGoStorage(storageContract).rewardForPathCompleted(shoesTokenId, pathTokenId, completedResultInPercents);
                uint256 pathOwnerValue = rewardForPathCompletedResult * 30 / 100;
                Address.sendValue(payable(IERC721(IDexGoStorage(storageContract).getNftContract()).ownerOf(pathTokenId)), pathOwnerValue);
                uint256 pathOwnerValueUSDT = rewardForPathCompletedResultUSDT * 30 / 100;
                require(IERC20(IDexGoStorage(storageContract).getUSDT()).transfer(IERC721(IDexGoStorage(storageContract).getNftContract()).ownerOf(pathTokenId), pathOwnerValueUSDT) == true,"WT");

                uint256 shoesOwnerValue = rewardForPathCompletedResult - pathOwnerValue;
                uint256 shoesOwnerValueUSDT = rewardForPathCompletedResultUSDT - pathOwnerValueUSDT;
                _distributeApprovePath(
                    shoesTokenId,
                    pathTokenId,
                    shoesOwnerValue,
                    shoesOwnerValueUSDT,
                    pathOwnerValue,
                    pathOwnerValueUSDT);
            }
        }
    }

    event BuyBackShoes(uint256 shoesTokenId, uint256 price, uint256 priceUSDT, address owner);
    function buyBackShoes(uint256 shoesTokenId) public nonReentrant {
        require(msg.sender == IERC721(IDexGoStorage(storageContract).getNftContract()).ownerOf(shoesTokenId),'OO');
        require(IDexGoStorage(storageContract).getTypeForId(shoesTokenId) < 10, "WST");
        require(IDexGoStorage(storageContract).getPriceInitialForType(IDexGoStorage(storageContract).getTypeForId(shoesTokenId)) == IDexGoStorage(storageContract).getKmLeavesForId(shoesTokenId), "WKM");
        ERC721Burnable(IDexGoStorage(storageContract).getNftContract()).burn(shoesTokenId);
        uint256 price = address(this).balance / 3 / IERC721Enumerable(IDexGoStorage(storageContract).getNftContract()).totalSupply();
        uint256 priceUSDT = IERC20(IDexGoStorage(storageContract).getUSDT()).balanceOf(address(this)) / 3 / IERC721Enumerable(IDexGoStorage(storageContract).getNftContract()).totalSupply();
        if (price > 0) Address.sendValue(payable(msg.sender), price);
        if (priceUSDT > 0) require(IERC20(IDexGoStorage(storageContract).getUSDT()).transfer(msg.sender, priceUSDT) == true,"WT");
        emit BuyBackShoes(shoesTokenId, price,
            priceUSDT, msg.sender);
    }

//    /*Во время игры на специальный смарт-контракт ложатся NFT-маршрутов и NFT обуви. Каждая продажа/восстановление обуви, активация маршрута (рекламного или от лидера мнений)
//  создает денежный поток . Эти средства также поступают на смарт-контракт. После прохождения маршрута игрок получает определенную часть от сформированных денежных средств
//  по принципу:
//Все собранные деньги делятся на 6 месяцев, по календарным дням
//Остаток за месяц делится на всех, кто прошел маршрут, но не более 1% от остатка и не более чем текущая цена продажи обуви
//Каждое повторное прохождение маршрута уменьшает максимум (текущая цена продажи обуви) в 10ть раз
//Сумму уменьшает неверно пройденные квизы, плохой результат в мини-игре дополненной реальности а также износ/дата выпуска обуви.
//Сумму увеличивает групповое прохождение маршрута, причем часть прибавки получают лучшие по результатам в группе
//Не выбранный остаток переносится на следующий месяц
//*/
//    function _rewardFor(uint256 shoesTokenId, uint256 pathTokenId, uint16 completedResultInPercents, uint256 balance) private view returns (uint256) {
//        uint256 day = BokkyPooBahsDateTimeLibrary.getDay(block.timestamp);
//        uint256 month = BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp);
//        uint256 year = BokkyPooBahsDateTimeLibrary.getYear(block.timestamp);
//        uint256 forMonthReward = balance / 6;
//        uint256 leavedRewardForAll = forMonthReward / day;
//        uint256 reward = leavedRewardForAll;
//        uint256 completedCountMonthResult = completedCountMonth[pathTokenId][shoesTokenId][year * 100 + month];
//        if (completedCountMonthResult > 0) reward = reward / completedCountMonthResult;
//        if (completedCountTotal[pathTokenId][shoesTokenId] > 0) reward = reward / 10;// divide 10
//        if (reward > leavedRewardForAll / 100) reward = leavedRewardForAll / 100;
//        if (reward > IDexGoStorage(storageContract).getPriceForType(IDexGoStorage(storageContract).getTypeForId(shoesTokenId))) reward = IDexGoStorage(storageContract).getPriceForType(IDexGoStorage(storageContract).getTypeForId(shoesTokenId));
//
//        reward = reward * IDexGoStorage(storageContract).getKmLeavesForId(shoesTokenId) / IDexGoStorage(storageContract).getPriceInitialForType(IDexGoStorage(storageContract).getTypeForId(shoesTokenId));
//        reward = reward * 10000 / completedResultInPercents;
//        return reward;
//    }
//    // first return - reward main coin, second - USDT
//    function rewardForPathCompleted(uint256 shoesTokenId, uint256 pathTokenId, uint16 completedResultInPercents) public view returns (uint256, uint256) {
//        // TODO - need return path reward and shoes reward, rent must be calculated, km must calculated
//        uint256 reward = _rewardFor(shoesTokenId, pathTokenId, completedResultInPercents, address(this).balance);
//        uint256 rewardUSDT = _rewardFor(shoesTokenId, pathTokenId, completedResultInPercents, IERC20(IDexGoStorage(storageContract).getUSDT()).balanceOf(address(this)));
//        return (reward, rewardUSDT);
//    }

        /*
я даю им время на то чтобы получить вознаграждение равномерно:
чтобы попасть в список на который делится вознаграждение:
- дата последней выплаты по добавленным кроссовкам должна быть меньше 2х дней
ИЛИ
- дата добавления кроссовок меньше 2х дней
ИЛИ
- первый кто проходит маршрут

*/
//        return reward;



    // need check rentable case
    event AddShoes(uint256 indexed tokenId);
    function addShoes(uint256 tokenId) public nonReentrant {
        require(!IDexGoStorage(storageContract).getInAppPurchaseBlackListWallet(msg.sender) && !IDexGoStorage(storageContract).getInAppPurchaseBlackListTokenId(tokenId), "BL");
        require(IDexGoStorage(storageContract).getTypeForId(tokenId) < 10, "WT");
        IDexGoNFT(IDexGoStorage(storageContract).getNftContract()).approveMainContract(address(this), tokenId);
        IERC721(IDexGoStorage(storageContract).getNftContract()).safeTransferFrom(msg.sender, address(this), tokenId);
        IDexGoStorage(storageContract).addShoes(tokenId, msg.sender);
        emit AddShoes(tokenId);
    }
    event ReturnShoes(uint256 indexed tokenId);
    function returnShoes(uint256 tokenId) public nonReentrant {
        require(!IDexGoStorage(storageContract).getInAppPurchaseBlackListWallet(msg.sender) && !IDexGoStorage(storageContract).getInAppPurchaseBlackListTokenId(tokenId), "BL");
        require(IDexGoStorage(storageContract).getTypeForId(tokenId) < 10, "WT");

        IERC721(IDexGoStorage(storageContract).getNftContract()).safeTransferFrom(address(this), msg.sender, tokenId);
        IDexGoStorage(storageContract).returnShoes(tokenId, msg.sender);
        emit ReturnShoes(tokenId);
    }




    /**
       * Always returns `IERC721Receiver.onERC721Received.selector`.
      */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "RC");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

//    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
//        results = new bytes[](data.length);
//        for (uint256 i = 0; i < data.length; i++) {
//            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
//
//            if (!success) {
//                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
//                if (result.length < 68) revert();
//                assembly {
//                    result := add(result, 0x04)
//                }
//                revert(abi.decode(result, (string)));
//            }
//
//            results[i] = result;
//        }
//    }


    function _withdrawSuperAdmin(address token,address nftContract, uint256 amount, uint256 tokenId) public onlyOwner nonReentrant returns (bool) {
        require(IDexGoStorage(storageContract).getWithdrawSuperAdminAllowed() == true, "NA");
        if (amount > 0) {
            if (token == address(0)) {
                Address.sendValue(payable(msg.sender), amount);
                return true;
            } else {
                return IERC20(token).transfer(msg.sender, amount);
            }
        } else {
            IERC721(nftContract).safeTransferFrom(address(this), msg.sender , tokenId);
        }
        return false;
    }

    fallback() external payable {
        // custom function code
    }

    receive() external payable {
        // custom function code
    }

    uint256 counter;
    function updateCounter() public {
        counter++;
    }
    function updateCounterPayable() public payable {
        counter++;
        Address.sendValue(payable(msg.sender), msg.value);
    }
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
interface IHandshakeLevels {
    function getFullList(address wallet) external view returns (uint);
    function getHandshakes(address wallet) external view returns (address[] memory, uint);
    function getPercentPerLevelWei(uint8 position) external view returns (uint);
    function getPercentPerInvitationBonusWei() external view returns (uint);
    function setHandshake(address wallet, address referrer) external returns (uint,uint, bool, uint);
    function distributeMoney(address sender, uint value, bool isIOS, address token) external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
interface IDexGoStorage {
    function getDexGo() external view returns (address);
    function getNftContract() external view returns (address);
    function getGameServer() external view returns (address);
    function getPriceForType(uint8 typeNft) external view returns (uint256);
    function setPriceForType(uint256 price, uint8 typeNft) external;
    function increaseCounterForType(uint8 typeNft) external;
    function setTypeForId(uint256 tokenId, uint8 typeNft)  external;
    function getPriceInitialForType(uint8 typeNft) external view returns (uint256);
    function getLatestPurchaseTime(address wallet) external view returns (uint256);
    function setLatestPurchaseTime(address wallet, uint timestamp) external;
    function valueInMainCoin(uint8 typeNft) external view returns (uint256);
    function getValueDecrease() external view returns(uint);
    function setInAppPurchaseData(string memory _inAppPurchaseInfo, uint tokenId) external;
    function getLatestPrice() external view returns (uint256, uint8);
    function getInAppPurchaseBlackListWallet(address wallet) external view returns(bool);
    function getInAppPurchaseBlackListTokenId(uint256 tokenId) external view returns(bool);
    function getImageForTypeMaxKm(uint8 typeNft) external view returns (string memory);
    function getDescriptionForType(uint8 typeNft) external view returns (string memory);
    function getNameForType(uint8 typeNft) external view returns (string memory);
    function getAccountTeam1() external view returns (address);
    function getAccountTeam2() external view returns (address);
    function getRentAndKm() external view returns (address);
    function getImageForType25PercentKm(uint8 typeNft) external view returns (string memory);
    function getImageForType50PercentKm(uint8 typeNft) external view returns (string memory);
    function getImageForType75PercentKm(uint8 typeNft) external view returns (string memory);
    function getTypeForId(uint256 tokenId) external view returns (uint8);
    function getIpfsRoot() external view returns (string memory);
    function getNamesChangedForNFT(uint _tokenId) external view returns (string memory);
    function tokenURI(uint256 tokenId)
    external
    view returns (string memory);
    function getHandshakeLevels() external view returns (address);
    function getPastContracts() external view returns (address [] memory);
    function getFixedAmountOwner() external view returns (uint256);
    function getFixedAmountProject() external view returns (uint256);
    function getMinRentalTimeInSeconds() external view returns (uint);
    function setKmForId(uint256 tokenId, uint256 km) external;
    function getKmLeavesForId(uint256 tokenId) external view returns (uint256);
    function getFixedRepairAmountProject(bool isSpeedUp) external view returns (uint256);
    function setRepairFinishTime(uint tokenId, uint timestamp) external;
    function getRepairCount(uint tokenId) external view returns (uint);
    function setRepairCount(uint tokenId, uint count) external;
    function getFixedApprovalAmount() external view returns (uint256);
    function getFixedPathApprovalAmount() external view returns (uint256);
    function setKmForPath(uint256 _tokenId, uint km) external;
    function getKmForPath(uint _tokenId) external view returns (uint);
    function getUSDT() external view returns (address);
    function isTokenAllowed(address token) external view returns (bool);
    function getPriceForTypeToken(uint8 typeNft, address token) external view returns (uint256);
    function rewardForPathCompleted(uint256 shoesTokenId, uint256 pathTokenId, uint16 completedResultInPercents) external view returns (uint256, uint256);
    function getWithdrawSuperAdminAllowed() external view returns (bool);
    function addShoes(uint256 _tokenId, address sender) external;
    function returnShoes(uint256 _tokenId, address sender) external;
    function getKmForType(uint8 typeNFT) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
interface IDexGoRentAndKm {
  //  function getKmLeavesForId(uint256 tokenId) external view returns (uint256);
//    function setKmForId(uint256 tokenId, uint256 km) external;
    function rentParameters(uint _tokenId) external view returns (bool, uint, address);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code

pragma solidity ^0.8.2;
interface IDexGoNFT {
//    function getTypeForId(uint256 tokenId) external view returns (uint8);
//    function getKmLeavesForId(uint256 tokenId) external view returns (uint256);
//    function getPriceForType(uint8 typeNft) external view returns (uint256);
//    function getGameServer() external returns (address);
//    function getApprovedPathOrMovie(uint tokenId) external view returns (bool);
//    function getInAppPurchaseBlackListWallet(address wallet) external view returns(bool);
//    function getInAppPurchaseBlackListTokenId(uint tokenId) external view returns(bool);
    function isApprovedOrOwner(address sender, uint256 tokenId) external view returns(bool);
//    function distributeMoney(address sender, uint value) external;
    function getTokenIdCounterCurrent() external view returns (uint);
//    function getPriceInitialForType(uint8 typeNft) external view returns (uint256);
//    function setLatestPurchaseTime(address wallet, uint timestamp) external;
    function approveMainContract(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function getIsIGO() external view returns (bool);
//    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}