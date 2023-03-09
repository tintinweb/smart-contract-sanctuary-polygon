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
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/merkleproof.sol";

// NON Launchpad Proxy
contract NONLaunchpadProxy is ILaunchpadProxy, Ownable, ReentrancyGuard {
    // example: proxy id, bytes4(keccak256("NONLaunchpadProxyV1"));V2 V3 V4 V5 ...
    bytes4 internal constant PROXY_ID =
        bytes4(keccak256("NONLaunchpadProxyV8"));
    // authority address to call this contract, (buy must call from external)
    mapping(address => bool) authorities;
    // default
    bool checkAuthority = true;
    // numLaunchpads
    uint256 public numLaunchpads;
    // launchpads
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
        bytes4 indexed launchpadId,
        bytes4 proxyId,
        address nftAddress,
        uint256 roundsIdx,
        address receipts,
        uint8 nftType,
        address sourceAddress
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

    /**
     * LaunchpadBuy - main method
     */
    function launchpadBuy(
        address sender,
        bytes4 launchpadId,
        uint256 roundsIdx,
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable override nonReentrant returns (uint256) {
        DataType.Launchpad storage lp = launchpads[launchpadId];
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
            lp,
            launchpadVars[launchpadId].accountRoundsStats[
                genRoundsAddressKey(sender, roundsIdx)
            ],
            roundsIdx,
            sender,
            quantity,
            proof
        );
        emit LaunchpadBuyEvt(
            PROXY_ID,
            launchpadId,
            roundsIdx,
            quantity,
            lp.roundss[roundsIdx].perIdQuantity,
            lp.sourceAddress,
            sender,
            lp.roundss[roundsIdx].buyToken,
            lp.targetContract,
            paymentValue
        );
        return paymentValue;
    }

    /**
     * LaunchpadSetBaseURI
     */
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

    /**
     * OnlyLPADController
     */
    function onlyLPADController(address msgSender, address controllerAdmin)
        internal
        view
    {
        require(
            owner() == msgSender || msgSender == controllerAdmin,
            LaunchpadProxyEnums.LPD_ONLY_CONTROLLER_COLLABORATOR_OWNER
        );
    }

    /**
     * ChangeAuthorizedAddress
     */
    function changeAuthorizedAddress(address target, bool opt)
        external
        onlyOwner
    {
        authorities[target] = opt;
        emit ChangeAuthorizedAddress(target, opt);
    }

    /**
     * SetCheckAuthority
     */
    function setCheckAuthority(bool checkAuth) external onlyOwner {
        checkAuthority = checkAuth;
    }

    /**
     * AddLaunchpadAndRounds, onlyOwner can call this (Only the platform has the core functions)
     */
    function addLaunchpadAndRounds(
        string memory name,
        address controllerAdmin,
        address targetContract,
        address receipts,
        bytes4[4] memory abiSelectorAndParam,
        DataType.LaunchpadRounds[] memory roundss,
        bool lockParam,
        bool enable,
        uint8 nftType,
        address sourceAddress
    ) external onlyOwner returns (bytes4) {
        numLaunchpads += 1;
        bytes4 launchpadId = bytes4(keccak256(bytes(name)));
        require(
            launchpads[launchpadId].id == 0,
            LaunchpadProxyEnums.LPD_ID_EXISTS
        );
        launchpads[launchpadId].enable = enable;
        launchpads[launchpadId].id = launchpadId;
        launchpads[launchpadId].nftType = nftType;
        launchpads[launchpadId].receipts = receipts;
        launchpads[launchpadId].lockParam = lockParam;
        launchpads[launchpadId].sourceAddress = sourceAddress;
        launchpads[launchpadId].targetContract = targetContract;
        launchpads[launchpadId].controllerAdmin = controllerAdmin;
        launchpads[launchpadId].abiSelectorAndParam = abiSelectorAndParam;
        for (uint256 i = 0; i < roundss.length; i++) {
            launchpads[launchpadId].roundss.push(roundss[i]);
            emit AddLaunchpadRoundData(roundss[i]);
        }
        uint256 idx = roundss.length - 1;
        emit AddLaunchpadData(
            launchpadId,
            PROXY_ID,
            targetContract,
            idx,
            receipts,
            nftType,
            sourceAddress
        );
        return launchpadId;
    }

    /**
     * UpdateLaunchpadController
     */
    function updateLaunchpadController(bytes4 launchpadId, address controller)
        external
        onlyOwner
    {
        launchpads[launchpadId].controllerAdmin = controller;
        emit SetLaunchpadController(controller);
    }

    /**
     * UpdateLaunchpadReceiptsParam
     */
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

    /**
     * UpdateLaunchpadEnableAndLocked enable-means can buy; lock-means can't change param by controller address;
     */
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

    /**
     * AddLaunchpadRounds
     */
    function addLaunchpadRounds(
        bytes4 launchpadId,
        DataType.LaunchpadRounds memory rounds
    ) external {
        onlyLPADController(
            _msgSender(),
            launchpads[launchpadId].controllerAdmin
        );
        launchpads[launchpadId].roundss.push(rounds);
    }

    /**
     * UpdateRoundsStartTimeAndFlags
     */
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

    /**
     * UpdateRoundsSupplyParam
     */
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

    /**
     * UpdateBuyTokenAndPrice
     */
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

    /**
     * UpdateTargetContractAndABIAndType
     */
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

    /**
     * UpdateStartTokenIdAndSaleQuantity, be careful to set startTokenId & SaleQuantity in the running launchpad
     */
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

    /**
     * AddRoundsWhiteLists
     */
    function addRoundsWhiteLists(
        bytes4 launchpadId,
        uint256 roundsIdx,
        DataType.WhiteListModel model,
        bytes32 merkleroot,
        uint8 wln
    ) external {
        DataType.Launchpad storage launchpad = launchpads[launchpadId];
        onlyLPADController(_msgSender(), launchpad.controllerAdmin);
        require(launchpad.id > 0, LaunchpadProxyEnums.LPD_INVALID_ID);
        launchpads[launchpadId].roundss[roundsIdx].merkleroot = merkleroot;
        launchpads[launchpadId].roundss[roundsIdx].wln = wln;
        launchpads[launchpadId].roundss[roundsIdx].whiteListModel = model;
    }

    /**
     * IsInWhiteList, is account in whitelist?  0 - not in whitelist;  > 0 means buy number,
     */
    function isInWhiteList(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address wl,
        bytes32[] calldata proof
    ) external view override returns (bool isWl) {
        return
            MerkleProof.verify(
                proof,
                launchpads[launchpadId].roundss[roundsIdx].merkleroot,
                LaunchpadBuy.leaf(wl)
            );
    }

    /**
     * GetLaunchpadInfo
     */
    function getLaunchpadInfo(bytes4 launchpadId)
        external
        view
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

    /**
     * GetLaunchpadRoundsInfo
     */
    function getLaunchpadRoundsInfo(bytes4 launchpadId, uint256 roundsIdx)
        external
        view
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

    /**
     * GetAccountInfoInLaunchpad
     */
    function getAccountInfoInLaunchpad(
        address sender,
        bytes4 launchpadId,
        uint256 roundsIdx
    ) external view returns (bool[] memory boolData, uint256[] memory intData) {
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
        intData[2] = lpadRounds.wln;
    }

    /**
     * IsWhiteListModel
     */
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

    /**
     * GetProxyId
     */
    function getProxyId() external pure override returns (bytes4) {
        return PROXY_ID;
    }

    /**
     * IsValidAddress
     */
    function isValidAddress(address addr) public pure returns (bool) {
        return address(addr) == addr && address(addr) != address(0);
    }

    /**
     * GenRoundsAddressKey, convert roundsIdx(96) + address(160) to a uint256 key
     */
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
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/merkleproof.sol";

library LaunchpadBuy {
    using SafeERC20 for IERC20;

    function processBuy(
        DataType.Launchpad storage lpad,
        DataType.AccountRoundsStats storage accountStats,
        uint256 roundsIdx,
        address sender,
        uint256 quantity,
        bytes32[] calldata proof
    ) internal returns (uint256) {
        DataType.LaunchpadRounds storage lpr = lpad.roundss[roundsIdx];
        DataType.LaunchpadRounds storage lprd = lpad.roundss[roundsIdx - 1];
        string memory ret = checkLaunchpadBuy(
            lpad,
            accountStats,
            roundsIdx,
            sender,
            quantity,
            proof
        );
        if (keccak256(bytes(ret)) != keccak256(bytes(LaunchpadProxyEnums.OK))) {
            revert(ret);
        }
        uint256 shouldPay = lpad.roundss[roundsIdx].price * quantity;
        uint256 nftType = lpad.nftType;
        address sourceAddress = lpad.sourceAddress;
        if (lpr.price > 0) {
            transferIncomes(lpad, sender, lpr.buyToken, shouldPay);
        }
        uint32 totalBuyQty = accountStats.totalBuyQty;
        accountStats.totalBuyQty = totalBuyQty + uint32(quantity);
        accountStats.lastBuyTime = uint32(block.timestamp);
        judge(lpad, roundsIdx, sender, quantity, nftType, sourceAddress, lprd);
        return shouldPay;
    }

    function judge(
        DataType.Launchpad storage lpad,
        uint256 roundsIdx,
        address sender,
        uint256 quantity,
        uint256 nftType,
        address sourceAddress,
        DataType.LaunchpadRounds storage lprd
    ) internal {
        if (roundsIdx != 0 && lprd.saleQuantity != lprd.maxSupply) {
            lpad.roundss[roundsIdx].startTokenId =
                lprd.saleQuantity +
                lprd.startTokenId;
            lpad.roundss[roundsIdx].maxSupply =
                lpad.roundss[roundsIdx].maxSupply +
                lprd.maxSupply -
                lprd.saleQuantity;
            lprd.maxSupply = lpad.roundss[roundsIdx - 1].saleQuantity;
        }
        if (nftType == 0) {
            callBuyNftTypeZero(
                lpad,
                quantity,
                sourceAddress,
                roundsIdx,
                sender
            );
        } else {
            callBuy(lpad, quantity, sourceAddress, roundsIdx, sender);
        }
    }

    function callBuyNftTypeZero(
        DataType.Launchpad storage lpadTransit,
        uint256 quantityTransit,
        address sourceAddress,
        uint256 roundsIdxTransit,
        address senderTransit
    ) internal {
        uint256 saleQuantity = lpadTransit
            .roundss[roundsIdxTransit]
            .saleQuantity;
        DataType.LaunchpadRounds memory lpadRounds = lpadTransit.roundss[
            roundsIdxTransit
        ];
        for (uint256 i = 0; i < quantityTransit; i++) {
            uint256 tokenId = lpadRounds.startTokenId + saleQuantity;
            callLaunchpadBuy(
                lpadTransit,
                senderTransit,
                quantityTransit,
                sourceAddress,
                tokenId
            );
            saleQuantity = saleQuantity + 1;
        }
        lpadTransit.roundss[roundsIdxTransit].saleQuantity = uint32(
            saleQuantity
        );
    }

    function callBuy(
        DataType.Launchpad storage lpadTransit,
        uint256 quantityTransit,
        address sourceAddress,
        uint256 roundsIdxTransit,
        address senderTransit
    ) internal {
        uint256 saleQuantity = lpadTransit
            .roundss[roundsIdxTransit]
            .saleQuantity;
        DataType.LaunchpadRounds memory lpadRounds = lpadTransit.roundss[
            roundsIdxTransit
        ];
        for (uint256 i = 0; i < quantityTransit; i++) {
            uint256 tokenId = lpadRounds.startTokenId + saleQuantity;
            uint256 perIdQuantity = lpadTransit
                .roundss[roundsIdxTransit]
                .perIdQuantity;
            callLaunchpadBuy(
                lpadTransit,
                senderTransit,
                perIdQuantity,
                sourceAddress,
                tokenId
            );
            saleQuantity = saleQuantity + 1;
        }
        lpadTransit.roundss[roundsIdxTransit].saleQuantity = uint32(
            saleQuantity
        );
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
                sourceAddress,
                sender,
                tokenId
            );
        } else if (paramTable == bytes4(0x00000003)) {
            proxyCallData = abi.encodeWithSelector(
                selector,
                sourceAddress,
                sender,
                tokenId,
                quantity
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
        bytes32[] calldata proof
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
        if (lpadRounds.price > 0) {
            uint256 paymentNeeded = quantity * lpadRounds.price;
            if (lpadRounds.buyToken != address(0)) {
                if (
                    paymentNeeded >
                    IERC20(lpadRounds.buyToken).balanceOf(sender)
                ) return LaunchpadProxyEnums.LPD_ROUNDS_ERC20_BLC_NOT_ENOUGH;
                if (
                    paymentNeeded >
                    IERC20(lpadRounds.buyToken).allowance(sender, address(this))
                )
                    return
                        LaunchpadProxyEnums
                            .LPD_ROUNDS_PAYMENT_ALLOWANCE_NOT_ENOUGH;
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
                    proof
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
            IERC20 token = IERC20(buyToken);
            token.safeTransferFrom(sender, lpad.receipts, shouldPay);
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
        bytes32[] calldata proof
    ) public view returns (string memory) {
        DataType.LaunchpadRounds memory lpadRounds = lpad.roundss[roundsIdx];
        if (
            !MerkleProof.verify(proof, lpadRounds.merkleroot, leaf(msg.sender))
        ) {
            return LaunchpadProxyEnums.LPD_ROUNDS_ADDRESS_NOT_IN_WHITELIST;
        }
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
        if (lpadRounds.wln == 0)
            return LaunchpadProxyEnums.LPD_ROUNDS_ACCOUNT_NOT_IN_WHITELIST;
        if ((quantity + alreadyBuy) > lpadRounds.wln)
            return LaunchpadProxyEnums.LPD_ROUNDS_WHITELIST_BUY_NUM_LIMIT;
        return LaunchpadProxyEnums.OK;
    }

    function leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
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
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable returns (uint256);

    function launchpadSetBaseURI(
        address sender,
        bytes4 launchpadId,
        string memory baseURI
    ) external;

    function isInWhiteList(
        bytes4 launchpadId,
        uint256 roundsIdx,
        address wl,
        bytes32[] calldata proof
    ) external view returns (bool isWl);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library LaunchpadProxyEnums {
    // 'ok'
    string public constant OK = "0";
    // 'only collaborator,owner can call'
    string public constant LPD_ONLY_COLLABORATOR_OWNER = "1";
    // 'only controller,collaborator,owner'
    string public constant LPD_ONLY_CONTROLLER_COLLABORATOR_OWNER = "2";
    // 'only authorities can call'
    string public constant LPD_ONLY_AUTHORITIES_ADDRESS = "3";
    // seprator err
    string public constant LPD_SEPARATOR = "4";
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
    // "rounds target contract address not valid"
    string public constant LPD_ROUNDS_TARGET_CONTRACT_INVALID = "12";
    // "invalid abi selector array not equal max"
    string public constant LPD_ROUNDS_ABI_ARRAY_LEN = "13";
    // 'buy from contract address not allowed'
    string public constant LPD_ROUNDS_BUY_FROM_CONTRACT_NOT_ALLOWED = "14";
    // 'sale not start yet'
    string public constant LPD_ROUNDS_SALE_NOT_START = "15";
    // 'max buy quantity one transaction limit'
    string public constant LPD_ROUNDS_MAX_BUY_QTY_PER_TX_LIMIT = "16";
    // 'quantity not enough to buy'
    string public constant LPD_ROUNDS_QTY_NOT_ENOUGH_TO_BUY = "17";
    // "payment not enough"
    string public constant LPD_ROUNDS_PAYMENT_NOT_ENOUGH = "18";
    // 'allowance not enough'
    string public constant LPD_ROUNDS_PAYMENT_ALLOWANCE_NOT_ENOUGH = "19";
    // "account max buy num limit"
    string public constant LPD_ROUNDS_ACCOUNT_MAX_BUY_LIMIT = "20";
    // 'account buy interval limit'
    string public constant LPD_ROUNDS_ACCOUNT_BUY_INTERVAL_LIMIT = "21";
    // 'not in whitelist'
    string public constant LPD_ROUNDS_ACCOUNT_NOT_IN_WHITELIST = "22";
    // 'buy selector invalid '
    string public constant LPD_ROUNDS_ABI_BUY_SELECTOR_INVALID = "23";
    // 'call buy contract fail'
    string public constant LPD_ROUNDS_CALL_BUY_CONTRACT_FAILED = "24";
    // 'call open contract fail'
    string public constant LPD_ROUNDS_CALL_OPEN_CONTRACT_FAILED = "25";
    // "erc20 balance not enough"
    string public constant LPD_ROUNDS_ERC20_BLC_NOT_ENOUGH = "26";
    // "eth send value not enough"
    string public constant LPD_ROUNDS_PAY_VALUE_NOT_ENOUGH = "27";
    // 'eth send value not need'
    string public constant LPD_ROUNDS_PAY_VALUE_NOT_NEED = "28";
    // 'eth send value upper need value'
    string public constant LPD_ROUNDS_PAY_VALUE_UPPER_NEED = "29";
    // 'not found abi to encode'
    string public constant LPD_ROUNDS_ABI_NOT_FOUND = "30";
    // 'sale end'
    string public constant LPD_ROUNDS_SALE_END = "31";
    // 'whitelist buy number limit'
    string public constant LPD_ROUNDS_WHITELIST_BUY_NUM_LIMIT = "32";
    // 'whitelist sale not start yet'
    string public constant LPD_ROUNDS_WHITELIST_SALE_NOT_START = "33";
    // 'whitelist sale not start yet'
    string public constant LPD_ROUNDS_ADDRESS_NOT_IN_WHITELIST = "34";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library DataType {
    // example: bytes4(keccak256("safeMint(address,uint256)"))
    uint256 internal constant ABI_IDX_BUY_SELECTOR = 0;
    // buy param example:
    // 0x00000000 - (address sender, uint256 tokenId),
    // 0x00000001 - (address sender, uint256 tokenId, uint256 quantity)
    // 0x00000002 - (address sourceAddress, address sender, uint256 tokenId)
    // 0x00000003 - (address sourceAddress, address sender, uint256 tokenId, uint256 quantity)
    uint256 internal constant ABI_IDX_BUY_PARAM_TABLE = 1;
    // example: bytes4(keccak256("setBaseURI(uint256)"))
    uint256 internal constant ABI_IDX_BASEURI_SELECTOR = 2;
    // setBaseURI param example:
    // 0x00000000 - (uint256 baseURI), default setBaseURI(uint256)
    uint256 internal constant ABI_IDX_BASEURI_PARAM_TABLE = 3;
    uint256 internal constant ABI_IDX_MAX = 4;
    // whiteListModel
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
        // buy start time, seconds UTC±0
        uint32 saleStart;
        // buy end time, seconds UTC±0
        uint32 saleEnd;
        // whitelist start time, seconds UTC±0
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
        // merkleroot
        bytes32 merkleroot;
        // wln
        uint8 wln;
    }

    // stats info for buyer account
    struct AccountRoundsStats {
        // last buy seconds,
        uint32 lastBuyTime;
        // total buy num already
        uint32 totalBuyQty;
    }

    // status info for launchpad
    struct LaunchpadVar {
        // account<->rounds stats； key: roundsIdx(96) + address(160), use genRoundsAddressKey()
        mapping(uint256 => AccountRoundsStats) accountRoundsStats;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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