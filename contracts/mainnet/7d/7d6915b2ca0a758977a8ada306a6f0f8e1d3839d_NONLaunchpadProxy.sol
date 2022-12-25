// SPDX-License-Identifier: MIT

//   _   _  ____  _   _   _                            _                     _   _____
//  | \ | |/ __ \| \ | | | |                          | |                   | | |  __ \
//  |  \| | |  | |  \| | | |     __ _ _   _ _ __   ___| |__  _ __   __ _  __| | | |__) | __ _____  ___   _
//  | . ` | |  | | . ` | | |    / _` | | | | '_ \ / __| '_ \| '_ \ / _` |/ _` | |  ___/ '__/ _ \ \/ / | | |
//  | |\  | |__| | |\  | | |___| (_| | |_| | | | | (__| | | | |_) | (_| | (_| | | |   | | | (_) >  <| |_| |
//  |_| \_|\____/|_| \_| |______\__,_|\__,_|_| |_|\___|_| |_| .__/ \__,_|\__,_| |_|   |_|  \___/_/\_\\__, |
//                                                          | |                                       __/ |
//                                                          |_|                                      |___/

pragma solidity ^0.8.16;

import "./data/DataType.sol";
import "./tools/LaunchpadBuy.sol";
import "./enum/LaunchpadProxyEnums.sol";
import "./interface/ILaunchpadProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// NON Launchpad Proxy
contract NONLaunchpadProxy is ILaunchpadProxy, Ownable, ReentrancyGuard {
    // example: proxy id, bytes4(keccak256("NONLaunchpadProxyV1"));V2 V3 V4 V5 ...
    bytes4 internal constant PROXY_ID =
        bytes4(keccak256("NONLaunchpadProxyV1"));
    // authority address to call this contract, (buy must call from external)
    mapping(address => bool) authorities;
    //def
    bool checkAuthority = true;
    uint256 public numLaunchpads;
    mapping(bytes4 => DataType.Launchpad) launchpads;
    // launchpad dynamic vars
    mapping(bytes4 => DataType.LaunchpadVar) launchpadVars;
    event ReceiptChange(
        bytes4 indexed launchpadId,
        address feeReceipts,
        address operator
    );
    event RoundsBuyTokenPriceChange(
        bytes4 indexed launchpadId,
        uint256 roundsIdx,
        address token,
        uint256 price
    );
    event ChangeAuthorizedAddress(address indexed target, bool addOrRemove);
    event SetLaunchpadController(address controllerAdmin);
    event AddLaunchpadData(
        string indexed launchpadName,
        bytes4 indexed launchpadId,
        bytes4 proxyId,
        address nftAddress,
        uint256 roundsIdx,
        address receipts,
        uint256 nftType,
        address sourceAddress,
        uint256 launchpadNum,
        address controllerAdmin,
        bool lockParam,
        bool enable
    );
    event AddLaunchpadRoundData(DataType.LaunchpadRounds round);
    event SetLaunchpadERC20AssetProxy(
        bytes4 proxyId,
        bytes4 indexed launchpadId,
        address erc20AssetProxy
    );
    event WhiteListAdd(
        bytes4 indexed launchpadId,
        address[] whitelist,
        uint8[] buyNum
    );
    event ChangeRoundsStartIdAndSaleQty(
        bytes4 proxyId,
        bytes4 indexed launchpadId,
        uint256 roundsIdx,
        uint256 startId,
        uint256 saleQty
    );
    event LaunchpadBuyEvt(
        bytes4 indexed proxyId,
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 quantity,
        uint256 perIdQuantity,
        address from,
        address to,
        address buyToken,
        address nftAddress,
        uint256 payValue
    );

    constructor() {}

    function launchpadSetBaseURI(
        address sender,
        bytes4 launchpadId,
        string memory baseURI
    ) external override nonReentrant {
        if (checkAuthority) {
            require(
                authorities[_msgSender()],
                LaunchpadProxyEnums.LPD_ONLY_AUTHORITIES_ADDRESS
            );
        } else {
            require(
                sender == _msgSender(),
                LaunchpadProxyEnums.SENDER_MUST_TX_CALLER
            );
        }
        bytes4 paramTable = launchpads[launchpadId].abiSelectorAndParam[
            DataType.ABI_IDX_BASEURI_PARAM_TABLE
        ];
        bytes4 selector = launchpads[launchpadId].abiSelectorAndParam[
            DataType.ABI_IDX_BASEURI_SELECTOR
        ];
        bytes memory proxyCallData;
        if (paramTable == bytes4(0x00000000)) {
            proxyCallData = abi.encodeWithSelector(selector, baseURI);
        }
        (bool didSucceed, bytes memory returnData) = launchpads[launchpadId]
            .targetContract
            .call(proxyCallData);
        if (!didSucceed) {
            revert(
                string(
                    abi.encodePacked(
                        LaunchpadProxyEnums
                            .LPD_ROUNDS_CALL_OPEN_CONTRACT_FAILED,
                        LaunchpadProxyEnums.LPD_SEPARATOR,
                        returnData
                    )
                )
            );
        }
    }

    function launchpadBuy(
        address sender,
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 quantity
    ) external payable override nonReentrant returns (uint256) {
        if (checkAuthority) {
            require(
                authorities[_msgSender()],
                LaunchpadProxyEnums.LPD_ONLY_AUTHORITIES_ADDRESS
            );
        } else {
            require(
                sender == _msgSender(),
                LaunchpadProxyEnums.SENDER_MUST_TX_CALLER
            );
        }
        uint256 paymentValue = LaunchpadBuy.processBuy(
            launchpads[launchpadId],
            launchpadVars[launchpadId].accountRoundsStats[
                genRoundsAddressKey(sender, roundsIdx)
            ],
            roundsIdx,
            sender,
            quantity
        );
        emit LaunchpadBuyEvt(
            PROXY_ID,
            launchpadId,
            roundsIdx,
            quantity,
            launchpads[launchpadId].roundss[roundsIdx].perIdQuantity,
            launchpads[launchpadId].sourceAddress,
            _msgSender(),
            launchpads[launchpadId].roundss[roundsIdx].buyToken,
            launchpads[launchpadId].targetContract,
            paymentValue
        );
        return paymentValue;
    }

    function onlyLPADController(address msgSender, address controllerAdmin)
        internal
        view
    {
        require(
            owner() == msgSender || msgSender == controllerAdmin,
            LaunchpadProxyEnums.LPD_ONLY_CONTROLLER_COLLABORATOR_OWNER
        );
    }

    function changeAuthorizedAddress(address target, bool opt)
        external
        onlyOwner
    {
        authorities[target] = opt;
        emit ChangeAuthorizedAddress(target, opt);
    }

    function setCheckAuthority(bool checkAuth) external onlyOwner {
        checkAuthority = checkAuth;
    }

    // add a new LaunchpadAndRounds, onlyOwner can call this (Only the platform has the core functions)
    function addLaunchpadAndRounds(
        string memory name,
        address controllerAdmin,
        address targetContract,
        address receipts,
        bytes4[4] memory abiSelectorAndParam,
        DataType.LaunchpadRounds[] memory roundss,
        bool lockParam,
        bool enable,
        uint256 nftType,
        address sourceAddress
    ) external onlyOwner returns (bytes4) {
        numLaunchpads += 1;
        bytes4 launchpadId = bytes4(keccak256(bytes(name)));
        require(
            launchpads[launchpadId].id == 0,
            LaunchpadProxyEnums.LPD_ID_EXISTS
        );
        launchpads[launchpadId].id = launchpadId;
        launchpads[launchpadId].controllerAdmin = controllerAdmin;
        launchpads[launchpadId].targetContract = targetContract;
        launchpads[launchpadId].abiSelectorAndParam = abiSelectorAndParam;
        launchpads[launchpadId].enable = enable;
        launchpads[launchpadId].lockParam = lockParam;
        launchpads[launchpadId].receipts = receipts;
        launchpads[launchpadId].nftType = nftType;
        launchpads[launchpadId].sourceAddress = sourceAddress;
        require(roundss.length > 0, LaunchpadProxyEnums.LPD_ROUNDS_HAVE_NO);
        for (uint256 i = 0; i < roundss.length; i++) {
            this.checkAddLaunchpadRounds(roundss[i]);
            launchpads[launchpadId].roundss.push(roundss[i]);
            emit AddLaunchpadRoundData(roundss[i]);
        }
        string memory nameTemp = name;
        address targetContractTemp = targetContract;
        address receiptsTemp = receipts;
        uint256 nftTypeTemp = nftType;
        address controllerAdminTemp = controllerAdmin;
        uint256 idx = roundss.length - 1;
        address sourceAddressTemp = sourceAddress;
        bool lockParamTemp = lockParam;
        bool enableTemp = enable;
        emit AddLaunchpadData(
            nameTemp,
            launchpadId,
            PROXY_ID,
            targetContractTemp,
            idx,
            receiptsTemp,
            nftTypeTemp,
            sourceAddressTemp,
            numLaunchpads,
            controllerAdminTemp,
            lockParamTemp,
            enableTemp
        );
        return launchpadId;
    }

    function updateLaunchpadController(bytes4 launchpadId, address controller)
        external
        onlyOwner
    {
        launchpads[launchpadId].controllerAdmin = controller;
        emit SetLaunchpadController(controller);
    }

    function updateLaunchpadReceiptsParam(bytes4 launchpadId, address receipts)
        external
    {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        require(
            !launchpads[launchpadId].lockParam,
            LaunchpadProxyEnums.LPD_PARAM_LOCKED
        );
        require(
            launchpads[launchpadId].id > 0,
            LaunchpadProxyEnums.LPD_INVALID_ID
        );
        launchpads[launchpadId].receipts = receipts;
        emit ReceiptChange(launchpads[launchpadId].id, receipts, msg.sender);
    }

    // update enable/lock; enable-means can buy; lock-means can't change param by controller address;
    function updateLaunchpadEnableAndLocked(
        bytes4 launchpadId,
        bool enable,
        bool lock
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        if (!lock) {
            require(
                _msgSender() != launchpads[launchpadId].controllerAdmin,
                LaunchpadProxyEnums.LPD_ONLY_COLLABORATOR_OWNER
            );
        }
        launchpads[launchpadId].lockParam = lock;
        launchpads[launchpadId].enable = enable;
    }

    function addLaunchpadRounds(
        bytes4 launchpadId,
        DataType.LaunchpadRounds memory rounds
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        this.checkAddLaunchpadRounds(rounds);
        launchpads[launchpadId].roundss.push(rounds);
    }

    function updateRoundsStartTimeAndFlags(
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 saleStart,
        uint256 saleEnd,
        uint256 whitelistStart
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        launchpads[launchpadId].roundss[roundsIdx].saleStart = uint32(
            saleStart
        );
        launchpads[launchpadId].roundss[roundsIdx].saleEnd = uint32(saleEnd);
        launchpads[launchpadId].roundss[roundsIdx].whiteListSaleStart = uint32(
            whitelistStart
        );
    }

    function updateRoundsSupplyParam(
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 maxSupply,
        uint256 maxBuyQtyPerAccount,
        uint256 maxBuyNumOnce,
        uint256 buyIntervalBlock,
        uint256 perIdQuantity
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );

        launchpads[launchpadId].roundss[roundsIdx].perIdQuantity = uint32(
            perIdQuantity
        );
        launchpads[launchpadId].roundss[roundsIdx].maxSupply = uint32(
            maxSupply
        );
        launchpads[launchpadId].roundss[roundsIdx].maxBuyQtyPerAccount = uint32(
            maxBuyQtyPerAccount
        );
        launchpads[launchpadId].roundss[roundsIdx].buyInterval = uint32(
            buyIntervalBlock
        );
        launchpads[launchpadId].roundss[roundsIdx].maxBuyNumOnce = uint32(
            maxBuyNumOnce
        );
    }

    function updateBuyTokenAndPrice(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address buyToken,
        uint256 buyPrice
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        require(
            !launchpads[launchpadId].lockParam,
            LaunchpadProxyEnums.LPD_PARAM_LOCKED
        );
        require(
            launchpads[launchpadId].id > 0,
            LaunchpadProxyEnums.LPD_INVALID_ID
        );
        launchpads[launchpadId].roundss[roundsIdx].buyToken = buyToken;
        launchpads[launchpadId].roundss[roundsIdx].price = uint128(buyPrice);
        emit RoundsBuyTokenPriceChange(
            launchpads[launchpadId].id,
            roundsIdx,
            buyToken,
            buyPrice
        );
    }

    function updateTargetContractAndABIAndType(
        bytes4 launchpadId,
        address target,
        uint256 nftType,
        address sourceAddress,
        bytes4[] memory abiSelector
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        require(
            abiSelector.length == DataType.ABI_IDX_MAX,
            LaunchpadProxyEnums.LPD_ROUNDS_ABI_ARRAY_LEN
        );
        require(
            isValidAddress(target),
            LaunchpadProxyEnums.LPD_ROUNDS_TARGET_CONTRACT_INVALID
        );
        require(
            abiSelector.length == DataType.ABI_IDX_MAX,
            LaunchpadProxyEnums.LPD_ROUNDS_ABI_ARRAY_LEN
        );
        require(
            abiSelector[DataType.ABI_IDX_BUY_SELECTOR] != bytes4(0),
            LaunchpadProxyEnums.LPD_ROUNDS_ABI_BUY_SELECTOR_INVALID
        );
        launchpads[launchpadId].targetContract = target;
        launchpads[launchpadId].nftType = nftType;
        launchpads[launchpadId].sourceAddress = sourceAddress;
        for (uint256 i = 0; i < DataType.ABI_IDX_MAX; i++) {
            launchpads[launchpadId].abiSelectorAndParam[i] = abiSelector[i];
        }
    }

    // !!! be careful to set startTokenId & SaleQuantity in the running launchpad
    function updateStartTokenIdAndSaleQuantity(
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 startTokenId,
        uint256 saleQuantity
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        require(
            !launchpads[launchpadId].lockParam,
            LaunchpadProxyEnums.LPD_PARAM_LOCKED
        );
        launchpads[launchpadId].roundss[roundsIdx].startTokenId = uint128(
            startTokenId
        );
        launchpads[launchpadId].roundss[roundsIdx].saleQuantity = uint32(
            saleQuantity
        );
        emit ChangeRoundsStartIdAndSaleQty(
            PROXY_ID,
            launchpadId,
            roundsIdx,
            startTokenId,
            saleQuantity
        );
    }

    function addOrRemoveRoundsWhiteLists(
        bytes4 launchpadId,
        uint256 roundsIdx,
        DataType.WhiteListModel model,
        address[] memory wls,
        uint8[] memory wln
    ) external {
        DataType.Launchpad storage launchpad = launchpads[launchpadId];
        onlyLPADController(_msgSender(), launchpad.controllerAdmin);
        require(launchpad.id > 0, LaunchpadProxyEnums.LPD_INVALID_ID);
        require(
            wls.length == wln.length,
            LaunchpadProxyEnums.LPD_INPUT_ARRAY_LEN_NOT_MATCH
        );
        for (uint256 i = 0; i < wls.length; i++) {
            // use address + roundsIdx make a uint256 unique key
            launchpadVars[launchpadId]
                .accountRoundsStats[genRoundsAddressKey(wls[i], roundsIdx)]
                .whiteListBuyNum = wln[i];
        }
        launchpads[launchpadId].roundss[roundsIdx].whiteListModel = model;

        emit WhiteListAdd(launchpadId, wls, wln);
    }

    // is account in whitelist?  0 - not in whitelist;  > 0 means buy number,
    function isInWhiteList(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address[] calldata wls
    ) external view override returns (uint8[] memory wln) {
        wln = new uint8[](wls.length);
        for (uint256 i = 0; i < wls.length; i++) {
            // use address + roundsIdx make a uint256 unique key
            wln[i] = launchpadVars[launchpadId]
                .accountRoundsStats[genRoundsAddressKey(wls[i], roundsIdx)]
                .whiteListBuyNum;
        }
    }

    function checkAddLaunchpadRounds(DataType.LaunchpadRounds memory rounds)
        external
        pure
    {
        require(
            rounds.maxSupply > 0,
            LaunchpadProxyEnums.LPD_ROUNDS_MAX_SUPPLY_INVALID
        );
        require(
            rounds.saleQuantity == 0,
            LaunchpadProxyEnums.LPD_ROUNDS_SALE_QUANTITY
        );
        require(
            (rounds.maxBuyQtyPerAccount > 0) &&
                (rounds.maxBuyQtyPerAccount <= rounds.maxSupply),
            LaunchpadProxyEnums.LPD_ROUNDS_MAX_BUY_QTY_INVALID
        );
        require(
            rounds.saleStart > 0,
            LaunchpadProxyEnums.LPD_ROUNDS_SALE_START_TIME_INVALID
        );
        require(
            rounds.saleEnd == 0 || rounds.saleEnd > rounds.saleStart,
            LaunchpadProxyEnums.LPD_ROUNDS_SALE_END_TIME_INVALID
        );
        require(rounds.price > 0, LaunchpadProxyEnums.LPD_ROUNDS_PRICE_INVALID);
    }

    function getLaunchpadInfo(bytes4 launchpadId)
        external
        view
        override
        returns (
            bool[] memory boolData,
            uint256[] memory intData,
            address[] memory addressData,
            bytes[] memory bytesData
        )
    {
        DataType.Launchpad memory lpad = launchpads[launchpadId];
        boolData = new bool[](2);
        boolData[0] = lpad.enable;
        boolData[1] = lpad.lockParam;

        bytesData = new bytes[](1);
        bytesData[0] = abi.encodePacked(lpad.id);

        addressData = new address[](5);
        addressData[0] = lpad.controllerAdmin;
        addressData[1] = address(this);
        addressData[2] = lpad.receipts;
        addressData[3] = lpad.targetContract;
        addressData[4] = lpad.sourceAddress;

        intData = new uint256[](2);
        intData[0] = lpad.roundss.length;
        intData[1] = lpad.nftType;
    }

    function getLaunchpadRoundsInfo(bytes4 launchpadId, uint256 roundsIdx)
        external
        view
        override
        returns (
            bool[] memory boolData,
            uint256[] memory intData,
            address[] memory addressData
        )
    {
        DataType.Launchpad memory lpad = launchpads[launchpadId];
        if (lpad.id == 0 || roundsIdx >= lpad.roundss.length) {
            return (boolData, intData, addressData);
        }

        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];

        boolData = new bool[](1);
        boolData[0] = lpad.enable;

        intData = new uint256[](10);
        intData[0] = lpadRounds.saleStart;
        intData[1] = uint256(lpadRounds.whiteListModel);
        intData[2] = lpadRounds.maxSupply;
        intData[3] = lpadRounds.saleQuantity;
        intData[4] = lpadRounds.maxBuyQtyPerAccount;
        intData[5] = lpadRounds.price;
        intData[6] = lpadRounds.startTokenId;
        intData[7] = lpadRounds.saleEnd;
        intData[8] = lpadRounds.whiteListSaleStart;
        intData[9] = lpadRounds.perIdQuantity;

        addressData = new address[](2);
        addressData[0] = lpadRounds.buyToken;
        addressData[1] = address(this);
    }

    function getAccountInfoInLaunchpad(
        address sender,
        bytes4 launchpadId,
        uint256 roundsIdx
    )
        external
        view
        override
        returns (bool[] memory boolData, uint256[] memory intData)
    {
        DataType.Launchpad memory lpad = launchpads[launchpadId];
        DataType.AccountRoundsStats memory accountStats = launchpadVars[
            launchpadId
        ].accountRoundsStats[genRoundsAddressKey(sender, roundsIdx)];
        if (lpad.id == 0 || roundsIdx >= lpad.roundss.length) {
            return (boolData, intData);
        }

        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];

        boolData = new bool[](2);
        boolData[0] = lpadRounds.whiteListModel != DataType.WhiteListModel.NONE;
        boolData[1] = isWhiteListModel(
            lpadRounds.whiteListModel,
            lpadRounds.whiteListSaleStart,
            lpadRounds.saleStart
        );

        intData = new uint256[](3);
        intData[0] = accountStats.totalBuyQty;
        // next buy time of this address
        intData[1] = accountStats.lastBuyTime + lpadRounds.buyInterval;
        // this whitelist user max can buy quantity
        intData[2] = accountStats.whiteListBuyNum;
    }

    function isWhiteListModel(
        DataType.WhiteListModel whiteListModel,
        uint32 whiteListSaleStart,
        uint32 saleStart
    ) internal view returns (bool) {
        if (whiteListModel == DataType.WhiteListModel.NONE) {
            return false;
        }
        if (whiteListSaleStart != 0) {
            if (block.timestamp >= saleStart) {
                return false;
            }
        }
        return true;
    }

    function getProxyId() external pure override returns (bytes4) {
        return PROXY_ID;
    }

    function isValidAddress(address addr) public pure returns (bool) {
        return address(addr) == addr && address(addr) != address(0);
    }

    // convert roundsIdx(96) + address(160) to a uint256 key
    function genRoundsAddressKey(address account, uint256 roundsIdx)
        public
        pure
        returns (uint256)
    {
        return
            (uint256(uint160(account)) &
                0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
            (roundsIdx << 160);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import "../data/DataType.sol";
import "../enum/LaunchpadProxyEnums.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LaunchpadBuy {
    function processBuy(
        DataType.Launchpad storage lpad,
        DataType.AccountRoundsStats storage accountStats,
        uint256 roundsIdx,
        address sender,
        uint256 quantity
    ) internal returns (uint256) {
        string memory ret = checkLaunchpadBuy(
            lpad,
            accountStats,
            roundsIdx,
            sender,
            quantity,
            accountStats.whiteListBuyNum
        );

        if (keccak256(bytes(ret)) != keccak256(bytes(LaunchpadProxyEnums.OK))) {
            revert(ret);
        }
        uint256 shouldPay = lpad.roundss[roundsIdx].price * quantity;
        uint256 nftType = lpad.nftType;
        address sourceAddress = lpad.sourceAddress;
        transferIncomes(
            lpad,
            sender,
            lpad.roundss[roundsIdx].buyToken,
            shouldPay
        );

        uint32 totalBuyQty = accountStats.totalBuyQty;
        accountStats.totalBuyQty = totalBuyQty + uint32(quantity);
        accountStats.lastBuyTime = uint32(block.timestamp);
        // Stack too deep
        DataType.Launchpad storage lpadTemp = lpad;
        if (
            roundsIdx != 0 &&
            lpad.roundss[roundsIdx - 1].saleQuantity !=
            lpad.roundss[roundsIdx - 1].maxSupply
        ) {
            lpad.roundss[roundsIdx].startTokenId =
                lpad.roundss[roundsIdx - 1].saleQuantity +
                lpad.roundss[roundsIdx - 1].startTokenId;
        }
        if (nftType == 0) {
            uint256 saleQuantity = lpad.roundss[roundsIdx].saleQuantity;
            DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[
                roundsIdx
            ];
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = lpadRounds.startTokenId + saleQuantity;
                callLaunchpadBuy(
                    lpadTemp,
                    sender,
                    quantity,
                    sourceAddress,
                    tokenId
                );
                saleQuantity = saleQuantity + 1;
            }
            lpad.roundss[roundsIdx].saleQuantity = uint32(saleQuantity);
        } else {
            uint256 saleQuantity = lpad.roundss[roundsIdx].saleQuantity;
            DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[
                roundsIdx
            ];
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = lpadRounds.startTokenId + saleQuantity;
                uint256 perIdQuantity = lpadTemp
                    .roundss[roundsIdx]
                    .perIdQuantity;
                callLaunchpadBuy(
                    lpadTemp,
                    sender,
                    perIdQuantity,
                    sourceAddress,
                    tokenId
                );
                saleQuantity = saleQuantity + 1;
            }
            lpad.roundss[roundsIdx].saleQuantity = uint32(saleQuantity);
        }
        return shouldPay;
    }

    function callLaunchpadBuy(
        DataType.Launchpad storage lpad,
        address sender,
        uint256 quantity,
        address sourceAddress,
        uint256 tokenId
    ) internal {
        // example bytes4(keccak256("safeMint(address,uint256)")),
        bytes4 selector = lpad.abiSelectorAndParam[
            DataType.ABI_IDX_BUY_SELECTOR
        ];
        bytes4 paramTable = lpad.abiSelectorAndParam[
            DataType.ABI_IDX_BUY_PARAM_TABLE
        ];
        bytes memory proxyCallData;
        if (paramTable == bytes4(0x00000000)) {
            proxyCallData = abi.encodeWithSelector(selector, sender, tokenId);
        } else if (paramTable == bytes4(0x00000001)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sender,
                tokenId,
                quantity
            );
        } else if (paramTable == bytes4(0x00000002)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sender,
                tokenId,
                "0x"
            );
        } else if (paramTable == bytes4(0x00000003)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sender,
                tokenId,
                quantity,
                "0x"
            );
        } else if (paramTable == bytes4(0x00000004)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sourceAddress,
                sender,
                tokenId
            );
        } else if (paramTable == bytes4(0x00000005)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sourceAddress,
                sender,
                tokenId,
                "0x"
            );
        } else if (paramTable == bytes4(0x00000006)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sourceAddress,
                sender,
                tokenId,
                quantity
            );
        } else if (paramTable == bytes4(0x00000007)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sourceAddress,
                sender,
                tokenId,
                quantity,
                "0x"
            );
        }
        require(
            proxyCallData.length > 0,
            LaunchpadProxyEnums.LPD_ROUNDS_ABI_NOT_FOUND
        );
        (bool didSucceed, bytes memory returnData) = lpad.targetContract.call(
            proxyCallData
        );
        if (!didSucceed) {
            revert(
                string(
                    abi.encodePacked(
                        LaunchpadProxyEnums.LPD_ROUNDS_CALL_BUY_CONTRACT_FAILED,
                        LaunchpadProxyEnums.LPD_SEPARATOR,
                        returnData
                    )
                )
            );
        }
    }

    function checkLaunchpadBuy(
        DataType.Launchpad memory lpad,
        DataType.AccountRoundsStats memory accStats,
        uint256 roundsIdx,
        address sender,
        uint256 quantity,
        uint256 wlMaxBuyQuantity
    ) internal returns (string memory) {
        if (lpad.id == 0) return LaunchpadProxyEnums.LPD_INVALID_ID;
        if (!lpad.enable) return LaunchpadProxyEnums.LPD_NOT_ENABLE;
        if (roundsIdx >= lpad.roundss.length)
            return LaunchpadProxyEnums.LPD_ROUNDS_IDX_INVALID;
        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];
        if (isContract(sender))
            return LaunchpadProxyEnums.LPD_ROUNDS_BUY_FROM_CONTRACT_NOT_ALLOWED;
        if ((quantity + lpadRounds.saleQuantity) > lpadRounds.maxSupply)
            return LaunchpadProxyEnums.LPD_ROUNDS_QTY_NOT_ENOUGH_TO_BUY;
        uint256 paymentNeeded = quantity * lpadRounds.price;
        if (lpadRounds.buyToken != address(0)) {
            if (paymentNeeded > IERC20(lpadRounds.buyToken).balanceOf(sender))
                return LaunchpadProxyEnums.LPD_ROUNDS_ERC20_BLC_NOT_ENOUGH;
            if (
                paymentNeeded >
                IERC20(lpadRounds.buyToken).allowance(sender, address(this))
            )
                return
                    LaunchpadProxyEnums.LPD_ROUNDS_PAYMENT_ALLOWANCE_NOT_ENOUGH;
            if (msg.value > 0)
                return LaunchpadProxyEnums.LPD_ROUNDS_PAY_VALUE_NOT_NEED;
        } else {
            if (paymentNeeded > (sender.balance + msg.value))
                return LaunchpadProxyEnums.LPD_ROUNDS_PAYMENT_NOT_ENOUGH;
            if (paymentNeeded > msg.value)
                return LaunchpadProxyEnums.LPD_ROUNDS_PAY_VALUE_NOT_ENOUGH;
            if (msg.value > paymentNeeded)
                return LaunchpadProxyEnums.LPD_ROUNDS_PAY_VALUE_UPPER_NEED;
        }
        if (quantity > lpadRounds.maxBuyNumOnce)
            return LaunchpadProxyEnums.LPD_ROUNDS_MAX_BUY_QTY_PER_TX_LIMIT;
        if ((quantity + accStats.totalBuyQty) > lpadRounds.maxBuyQtyPerAccount)
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_MAX_BUY_LIMIT;
        if (block.timestamp - accStats.lastBuyTime < lpadRounds.buyInterval)
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_BUY_INTERVAL_LIMIT;
        if (lpadRounds.saleEnd > 0 && block.timestamp > lpadRounds.saleEnd)
            return LaunchpadProxyEnums.LPD_ROUNDS_SALE_END;
        if (lpadRounds.whiteListModel != DataType.WhiteListModel.NONE) {
            return
                checkWhitelistBuy(
                    lpad,
                    roundsIdx,
                    quantity,
                    accStats.totalBuyQty,
                    wlMaxBuyQuantity
                );
        } else {
            if (block.timestamp < lpadRounds.saleStart)
                return LaunchpadProxyEnums.LPD_ROUNDS_SALE_NOT_START;
        }
        return LaunchpadProxyEnums.OK;
    }

    function transferIncomes(
        DataType.Launchpad memory lpad,
        address sender,
        address buyToken,
        uint256 shouldPay
    ) internal {
        if (shouldPay == 0) {
            return;
        }
        if (buyToken == address(0)) {
            payable(lpad.receipts).transfer(shouldPay);
        } else {
            IERC20(buyToken).transferFrom(sender, lpad.receipts, shouldPay);
        }
    }

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    //                     [whitelist sale]                  [public sale]
    //  | whiteListSaleStart ---------- saleStart | saleStart ---------- saleEnd |
    function checkWhitelistBuy(
        DataType.Launchpad memory lpad,
        uint256 roundsIdx,
        uint256 quantity,
        uint256 alreadyBuy,
        uint256 maxWhitelistBuy
    ) public view returns (string memory) {
        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];
        if (lpadRounds.whiteListSaleStart != 0) {
            if (lpadRounds.saleStart < block.timestamp) {
                return LaunchpadProxyEnums.OK;
            }
            if (block.timestamp < lpadRounds.whiteListSaleStart)
                return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_SALE_NOT_START;
        } else {
            if (block.timestamp < lpadRounds.saleStart)
                return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_SALE_NOT_START;
        }
        if (maxWhitelistBuy == 0)
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_NOT_IN_WHITELIST;
        if ((quantity + alreadyBuy) > maxWhitelistBuy)
            return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_BUY_NUM_LIMIT;
        return LaunchpadProxyEnums.OK;
    }
}

// SPDX-License-Identifier: MIT

//   _   _  ____  _   _   _____ _                            _                     _ _____
//  | \ | |/ __ \| \ | | |_   _| |                          | |                   | |  __ \
//  |  \| | |  | |  \| |   | | | |     __ _ _   _ _ __   ___| |__  _ __   __ _  __| | |__) | __ _____  ___   _
//  | . ` | |  | | . ` |   | | | |    / _` | | | | '_ \ / __| '_ \| '_ \ / _` |/ _` |  ___/ '__/ _ \ \/ / | | |
//  | |\  | |__| | |\  |  _| |_| |___| (_| | |_| | | | | (__| | | | |_) | (_| | (_| | |   | | | (_) >  <| |_| |
//  |_| \_|\____/|_| \_| |_____|______\__,_|\__,_|_| |_|\___|_| |_| .__/ \__,_|\__,_|_|   |_|  \___/_/\_\\__, |
//                                                                | |                                     __/ |
//                                                                |_|                                    |___/                                                          |_|

pragma solidity ^0.8.16;

interface ILaunchpadProxy {
    function getProxyId() external pure returns (bytes4);

    function launchpadBuy(
        address sender,
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 quantity
    ) external payable returns (uint256);

    function launchpadSetBaseURI(
        address sender,
        bytes4 launchpadId,
        string memory baseURI
    ) external;

    function getLaunchpadInfo(bytes4 launchpadId)
        external
        view
        returns (
            bool[] memory boolData,
            uint256[] memory intData,
            address[] memory addressData,
            bytes[] memory bytesData
        );

    function getLaunchpadRoundsInfo(bytes4 launchpadId, uint256 roundsIdx)
        external
        view
        returns (
            bool[] memory boolData,
            uint256[] memory intData,
            address[] memory addressData
        );

    function getAccountInfoInLaunchpad(
        address sender,
        bytes4 launchpadId,
        uint256 roundsIdx
    ) external view returns (bool[] memory boolData, uint256[] memory intData);

    function isInWhiteList(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address[] calldata accounts
    ) external view returns (uint8[] memory wln);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library LaunchpadProxyEnums {
    // 'ok'
    string public constant OK = "0";
    // 'only collaborator,owner can call'
    string public constant LPD_ONLY_COLLABORATOR_OWNER = "1";
    //  'only controller,collaborator,owner'
    string public constant LPD_ONLY_CONTROLLER_COLLABORATOR_OWNER = "2";
    // 'only authorities can call'
    string public constant LPD_ONLY_AUTHORITIES_ADDRESS = "3";
    // 'transfer eth failed'
    string public constant TRANSFER_ETH_FAILED = "4";
    // 'sender must transaction caller'
    string public constant SENDER_MUST_TX_CALLER = "5";
    // 'launchpad invalid id'
    string public constant LPD_INVALID_ID = "6";
    // 'launchpadId exists'
    string public constant LPD_ID_EXISTS = "7";
    // 'launchpad not enable'
    string public constant LPD_NOT_ENABLE = "8";
    // 'input array len not match'
    string public constant LPD_INPUT_ARRAY_LEN_NOT_MATCH = "9";
    // 'launchpad param locked'
    string public constant LPD_PARAM_LOCKED = "10";
    // 'launchpad rounds idx invalid'
    string public constant LPD_ROUNDS_IDX_INVALID = "11";
    // 'max supply invalid'
    string public constant LPD_ROUNDS_MAX_SUPPLY_INVALID = "12";
    // 'initial sale quantity must 0'
    string public constant LPD_ROUNDS_SALE_QUANTITY = "13";
    // "rounds target contract address not valid"
    string public constant LPD_ROUNDS_TARGET_CONTRACT_INVALID = "14";
    // "invalid abi selector array not equal max"
    string public constant LPD_ROUNDS_ABI_ARRAY_LEN = "15";
    // "max buy qty invalid"
    string public constant LPD_ROUNDS_MAX_BUY_QTY_INVALID = "16";
    // 'flag array len not equal max'
    string public constant LPD_ROUNDS_FLAGS_ARRAY_LEN = "17";
    // 'buy from contract address not allowed'
    string public constant LPD_ROUNDS_BUY_FROM_CONTRACT_NOT_ALLOWED = "18";
    // 'sale not start yet'
    string public constant LPD_ROUNDS_SALE_NOT_START = "19";
    // 'max buy quantity one transaction limit'
    string public constant LPD_ROUNDS_MAX_BUY_QTY_PER_TX_LIMIT = "20";
    // 'quantity not enough to buy'
    string public constant LPD_ROUNDS_QTY_NOT_ENOUGH_TO_BUY = "21";
    // "payment not enough"
    string public constant LPD_ROUNDS_PAYMENT_NOT_ENOUGH = "22";
    // 'allowance not enough'
    string public constant LPD_ROUNDS_PAYMENT_ALLOWANCE_NOT_ENOUGH = "23";
    // "account max buy num limit"
    string public constant LPD_ROUNDS_ACCOUNT_MAX_BUY_LIMIT = "24";
    // 'account buy interval limit'
    string public constant LPD_ROUNDS_ACCOUNT_BUY_INTERVAL_LIMIT = "25";
    // 'not in whitelist'
    string public constant LPD_ROUNDS_ACCOUNT_NOT_IN_WHITELIST = "26";
    // 'buy selector invalid '
    string public constant LPD_ROUNDS_ABI_BUY_SELECTOR_INVALID = "27";
    // 'sale time invalid'
    string public constant LPD_ROUNDS_SALE_START_TIME_INVALID = "28";
    // 'price must > 0'
    string public constant LPD_ROUNDS_PRICE_INVALID = "29";
    // 'call buy contract fail'
    string public constant LPD_ROUNDS_CALL_BUY_CONTRACT_FAILED = "30";
    // 'call open contract fail'
    string public constant LPD_ROUNDS_CALL_OPEN_CONTRACT_FAILED = "31";
    // "erc20 balance not enough"
    string public constant LPD_ROUNDS_ERC20_BLC_NOT_ENOUGH = "32";
    // "eth send value not enough"
    string public constant LPD_ROUNDS_PAY_VALUE_NOT_ENOUGH = "33";
    // 'eth send value not need'
    string public constant LPD_ROUNDS_PAY_VALUE_NOT_NEED = "34";
    // 'eth send value upper need value'
    string public constant LPD_ROUNDS_PAY_VALUE_UPPER_NEED = "35";
    // 'not found abi to encode'
    string public constant LPD_ROUNDS_ABI_NOT_FOUND = "36";
    // 'sale end'
    string public constant LPD_ROUNDS_SALE_END = "37";
    // 'sale end time invalid'
    string public constant LPD_ROUNDS_SALE_END_TIME_INVALID = "38";
    // 'whitelist buy number limit'
    string public constant LPD_ROUNDS_WHITELIST_BUY_NUM_LIMIT = "39";
    // 'whitelist sale not start yet'
    string public constant LPD_ROUNDS_WHITELIST_SALE_NOT_START = "40";
    // 'rounds have no'
    string public constant LPD_ROUNDS_HAVE_NO = "41";
    // seprator err
    string public constant LPD_SEPARATOR = "42";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library DataType {
    // ABI
    // example: bytes4(keccak256("safeMint(address,uint256)"))
    uint256 internal constant ABI_IDX_BUY_SELECTOR = 0;
    // buy param example:
    // 0x00000000 - (address sender, uint256 tokenId),
    // 0x00000001 - (address sender, uint256 tokenId, uint256 quantity)
    // 0x00000002 - (address sender, uint256 tokenId, bytes data)
    // 0x00000003 - (address sender, uint256 tokenId, uint256 quantity, bytes data)
    // 0x00000004 - (address sourceAddress, address sender, uint256 tokenId)
    // 0x00000005 - (address sourceAddress, address sender, uint256 tokenId, bytes data)
    // 0x00000006 - (address sourceAddress, address sender, uint256 tokenId, uint256 quantity)
    // 0x00000007 - (address sourceAddress, address sender, uint256 tokenId, uint256 quantity, bytes data)
    uint256 internal constant ABI_IDX_BUY_PARAM_TABLE = 1;
    // example: bytes4(keccak256("setBaseURI(uint256)"))
    uint256 internal constant ABI_IDX_BASEURI_SELECTOR = 2;
    // setBaseURI param example:
    // 0x00000000 - (uint256 baseURI), default setBaseURI(uint256)
    uint256 internal constant ABI_IDX_BASEURI_PARAM_TABLE = 3;
    uint256 internal constant ABI_IDX_MAX = 4;

    enum WhiteListModel {
        NONE, // 0 - No White List
        ON_CHAIN_CHECK // 1 - Check address on-chain
    }

    // launchpad 1
    struct Launchpad {
        // id of launchpad
        bytes4 id;
        // target contract of 3rd project,
        address targetContract;
        // 0-buy abi, 1-buy param, 2-setBaseURI abi, 3-setBaseURI param
        bytes4[ABI_IDX_MAX] abiSelectorAndParam;
        // enable
        bool enable;
        // lock the launchpad param, can't change except owner
        bool lockParam;
        // admin to config this launchpad params
        address controllerAdmin;
        // receipts address
        address receipts;
        // launchpad rounds info detail
        LaunchpadRounds[] roundss;
        // launchpad nftType 0:721/ 1:1155
        uint256 nftType;
        // launchpad sourceAddress transfer use
        address sourceAddress;
    }

    // 1 launchpad have N rounds
    struct LaunchpadRounds {
        // price of normal user account, > 8888 * 10**18 means
        uint128 price;
        // start token id, most from 0
        uint128 startTokenId;
        // buy token
        address buyToken;
        // white list model
        WhiteListModel whiteListModel;
        // buy start time, seconds
        uint32 saleStart;
        // buy end time, seconds
        uint32 saleEnd;
        // whitelist start time
        uint32 whiteListSaleStart;
        // perIdQuantity 721:1 , 1155:n
        uint32 perIdQuantity;
        // max supply of this rounds
        uint32 maxSupply;
        // current sale number, must from 0
        uint32 saleQuantity;
        // max buy qty per address
        uint32 maxBuyQtyPerAccount;
        // max buy num one tx
        uint32 maxBuyNumOnce;
        // next buy time till last buy, seconds
        uint32 buyInterval;
    }

    // stats info for buyer account
    struct AccountRoundsStats {
        // last buy seconds,
        uint32 lastBuyTime;
        // total buy num already
        uint32 totalBuyQty;
        // 0 - not in whitelist, > 0 number can buy of this whitelist user
        uint8 whiteListBuyNum;
    }

    // status info for launchpad
    struct LaunchpadVar {
        // account<->rounds stats； key: roundsIdx(96) + address(160), use genRoundsAddressKey()
        mapping(uint256 => AccountRoundsStats) accountRoundsStats;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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