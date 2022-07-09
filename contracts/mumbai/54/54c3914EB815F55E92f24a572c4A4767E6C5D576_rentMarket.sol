// This code has not been professionally audited,
// therefore we cannot make any promises about
// safety or correctness. Use at own risk.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
import "./iterableMapLib.sol";

//
// Error messages.
//
// RM1 : The same element is already request.
// RM2 : The same element is already register.
// RM3 : No element in register.
// RM4 : Sender is not the owner of NFT.
// RM5 : Sender is not the owner of NFT or the owner of rentMarket.
// RM6 : No register for this service address.
// RM7 : No register data for this NFT.
// RM8 : Transaction value is not same as the rent fee.
// RM9 : Already rented.
// RM10 : No rent data in renteeDataMap for this NFT.
// RM11 : msg.sender should be same as renteeAddress.
// RM12 : Sum should be 100.
// RM13 : msg.sender should be zero, because of erc20 payment.
// RM14 : Failed to recipient.call.

/// @title A rentMarket class.
/// @author A realbits dev team.
/// @notice You can use this contract for only testing purpose now.
/// @dev All function calls are currently being tested.
contract rentMarket is Ownable {
    // Iterable mapping data type with library.
    using pendingRentFeeIterableMap for pendingRentFeeIterableMap.pendingRentFeeMap;
    using accountBalanceIterableMap for accountBalanceIterableMap.accountBalanceMap;
    using tokenDataIterableMap for tokenDataIterableMap.tokenDataMap;
    using serviceDataIterableMap for serviceDataIterableMap.serviceDataMap;
    using requestDataIterableMap for requestDataIterableMap.requestDataMap;
    using registerDataIterableMap for registerDataIterableMap.registerDataMap;
    using rentDataIterableMap for rentDataIterableMap.rentDataMap;

    // Market fee receiver address.
    address private MARKET_SHARE_ADDRESS;

    // blockHeight(2) * 30 * 60 * 24 * 30 (1 month) : 2,592,000
    uint256 private constant ONE_MONTH_BLOCK_HEIGHT = 2_592_000;
    // default rent fee as finney (1e15) unit (1e18 is ether unit).
    uint256 private RENT_FEE = 1000_000 gwei;
    // default rent duration as block number unit.
    uint256 private RENT_DURATION = 100;

    // default renter fee quota.
    uint256 private RENTER_FEE_QUOTA = 35;

    // default service fee quota.
    uint256 private SERVICE_FEE_QUOTA = 35;

    // default market fee quota.
    uint256 private MARKET_FEE_QUOTA = 30;

    // Data for token.
    tokenDataIterableMap.tokenDataMap tokenItMap;

    // Data for service.
    serviceDataIterableMap.serviceDataMap serviceItMap;

    // Data for request NFT register.
    requestDataIterableMap.requestDataMap requestDataItMap;
    // Data for register and unregister.
    registerDataIterableMap.registerDataMap registerDataItMap;

    // Data for rent and unrent.
    rentDataIterableMap.rentDataMap rentDataItMap;

    // Accumulated rent fee record map per renter address.
    pendingRentFeeIterableMap.pendingRentFeeMap pendingRentFeeMap;
    // Data for account balance data when settleRentData.
    accountBalanceIterableMap.accountBalanceMap accountBalanceItMap;

    //--------------------------------------------------------------------------
    //
    // TOKEN FLOW
    // SERVICE FLOW
    // NFT FLOW
    //
    // MARKET_ADDRESS
    // BALANCE
    // QUOTA
    //
    // RENT FLOW
    // SETTLE FLOW
    // WITHDRAW FLOW
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // CONSTRUCTOR
    //--------------------------------------------------------------------------

    // Set market share address to this self contract address.
    constructor() {
        MARKET_SHARE_ADDRESS = msg.sender;
    }

    event Fallback(address indexed sender);

    fallback() external payable {
        emit Fallback(msg.sender);
    }

    event Receive(address indexed sender, uint256 indexed value);

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    //--------------------------------------------------------------------------
    //---------------------------------- TOKEN FLOW ----------------------------
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // TOKEN EVENT
    //--------------------------------------------------------------------------

    // Declare register token.
    event RegisterToken(address indexed tokenAddress, string indexed name);

    // Declare unregister token.
    event UnregisterToken(address indexed serviceAddress, string indexed name);

    //--------------------------------------------------------------------------
    // TOKEN GET/REMOVE FUNCTION
    //--------------------------------------------------------------------------

    /// @notice Return all token data as array type
    /// @return All token data as array
    function getAllToken()
        public
        view
        returns (tokenDataIterableMap.tokenData[] memory)
    {
        tokenDataIterableMap.tokenData[]
            memory data = new tokenDataIterableMap.tokenData[](
                tokenItMap.keys.length
            );

        for (uint256 i = 0; i < tokenItMap.keys.length; i++) {
            data[i] = tokenItMap.data[tokenItMap.keys[i]].data;
        }

        return data;
    }

    /// @notice Warning: This function will delete all token data.
    function removeAllToken() public onlyOwner {
        for (uint256 i = 0; i < tokenItMap.keys.length; i++) {
            delete tokenItMap.data[tokenItMap.keys[i]];
        }

        delete tokenItMap.keys;
    }

    //--------------------------------------------------------------------------
    // TOKEN REGISTER/CHANGE/UNREGISTER FUNCTION
    //--------------------------------------------------------------------------

    /// @notice Register token
    /// @param tokenAddress token address
    function registerToken(address tokenAddress, string memory name)
        public
        onlyOwner
    {
        // 1. Check the duplicate element in request data.
        require(tokenItMap.contains(tokenAddress) == false, "RM1");

        // 2. Add request token data.
        tokenItMap.insert(tokenAddress, name);

        // 3. Emit RequestRegisterToken event.
        emit RegisterToken(tokenAddress, name);
    }

    /// @notice Unregister token data
    /// @param tokenAddress token address
    function unregisterToken(address tokenAddress) public onlyOwner {
        // 2. Check the duplicate element.
        require(tokenItMap.contains(tokenAddress) == true, "RM3");

        // 3. Get data.
        tokenDataIterableMap.tokenData memory data = tokenItMap.getByAddress(
            tokenAddress
        );

        // 4. Delete tokenItMap.
        tokenItMap.remove(tokenAddress);

        // 5. Emit UnregisterToken event.
        emit UnregisterToken(data.tokenAddress, data.name);
    }

    //--------------------------------------------------------------------------
    //---------------------------------- SERVICE FLOW --------------------------
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // SERVICE EVENT
    //--------------------------------------------------------------------------

    // Declare register service.
    event RegisterService(address indexed serviceAddress, string indexed name);

    // Declare unregister service.
    event UnregisterService(
        address indexed serviceAddress,
        string indexed name
    );

    //--------------------------------------------------------------------------
    // SERVICE GET/REMOVE FUNCTION
    //--------------------------------------------------------------------------

    /// @notice Return all service data as array type
    /// @return All service data as array
    function getAllService()
        public
        view
        returns (serviceDataIterableMap.serviceData[] memory)
    {
        serviceDataIterableMap.serviceData[]
            memory data = new serviceDataIterableMap.serviceData[](
                serviceItMap.keys.length
            );

        for (uint256 i = 0; i < serviceItMap.keys.length; i++) {
            data[i] = serviceItMap.data[serviceItMap.keys[i]].data;
        }

        return data;
    }

    /// @notice Return matched service data with service address.
    /// @param serviceAddress service address
    /// @return Matched service data
    function getService(address serviceAddress)
        public
        view
        returns (serviceDataIterableMap.serviceData memory)
    {
        return serviceItMap.getByAddress(serviceAddress);
    }

    /// @notice Warning: This function will delete all service data.
    function removeAllService() public onlyOwner {
        for (uint256 i = 0; i < serviceItMap.keys.length; i++) {
            delete serviceItMap.data[serviceItMap.keys[i]];
        }

        delete serviceItMap.keys;
    }

    //--------------------------------------------------------------------------
    // SERVICE REGISTER/UNREGISTER FUNCTION
    //--------------------------------------------------------------------------

    /// @notice Register service
    /// @param serviceAddress service address
    function registerService(address serviceAddress, string memory name)
        public
        onlyOwner
    {
        // 1. Check the duplicate element in service data.
        require(serviceItMap.contains(serviceAddress) == false, "RM1");

        // 2. Add service data.
        serviceItMap.insert(serviceAddress, name);

        // 3. Emit RegisterService event.
        emit RegisterService(serviceAddress, name);
    }

    /// @notice Unregister service data
    /// @param serviceAddress service address
    function unregisterService(address serviceAddress) public onlyOwner {
        // 1. Check the duplicate element.
        require(serviceItMap.contains(serviceAddress) == true, "RM3");

        // 2. Get data.
        serviceDataIterableMap.serviceData memory data = serviceItMap
            .getByAddress(serviceAddress);

        // 3. Delete registerServiceItMap.
        serviceItMap.remove(serviceAddress);

        // 4. Emit UnregisterService event.
        emit UnregisterService(data.serviceAddress, data.name);
    }

    //--------------------------------------------------------------------------
    //---------------------------------- NFT FLOW ------------------------------
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // NFT EVENT
    //--------------------------------------------------------------------------

    // Declare request register NFT event.
    event RequestRegisterNFT(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed NFTOwnerAddress
    );

    // Declare accept register NFT event.
    event AcceptRegisterNFT(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 rentFee,
        uint256 rentDuration,
        address indexed NFTOwnerAddress
    );

    // Declare change NFT event.
    // TODO : Should check register address.
    event ChangeNFT(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        uint256 rentDuration,
        address NFTOwnerAddress,
        address indexed changerAddress
    );

    // Declare unrequest NFT event.
    event UnrequestNFT(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address NFTOwnerAddress,
        address indexed UnrequesterAddress
    );

    // Declare unregister NFT event.
    event UnregisterNFT(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        uint256 rentDuration,
        address NFTOwnerAddress,
        address indexed UnregisterAddress
    );

    //--------------------------------------------------------------------------
    // NFT GET/REMOVE FUNCTION
    //--------------------------------------------------------------------------

    /// @notice Return all request data as array type
    /// @return All request data as array
    function getAllRequestData()
        public
        view
        returns (requestDataIterableMap.requestData[] memory)
    {
        requestDataIterableMap.requestData[]
            memory data = new requestDataIterableMap.requestData[](
                requestDataItMap.keys.length
            );

        for (uint256 i = 0; i < requestDataItMap.keys.length; i++) {
            data[i] = requestDataItMap.data[requestDataItMap.keys[i]].data;
        }

        return data;
    }

    /// @notice Return matched request data with NFT address and token ID
    /// @param nftAddress NFT address
    /// @param tokenId token ID
    /// @return Matched request data
    function getRequestData(address nftAddress, uint256 tokenId)
        public
        view
        returns (requestDataIterableMap.requestData memory)
    {
        return requestDataItMap.getByNFT(nftAddress, tokenId);
    }

    /// @notice Warning: This function will delete all request NFT data.
    function removeAllRequestData() public onlyOwner {
        for (uint256 i = 0; i < requestDataItMap.keys.length; i++) {
            delete requestDataItMap.data[requestDataItMap.keys[i]];
        }

        delete requestDataItMap.keys;
    }

    /// @notice Return all registered data as array type
    /// @return All registered data as array
    function getAllRegisterData()
        public
        view
        returns (registerDataIterableMap.registerData[] memory)
    {
        registerDataIterableMap.registerData[]
            memory data = new registerDataIterableMap.registerData[](
                registerDataItMap.keys.length
            );

        for (uint256 i = 0; i < registerDataItMap.keys.length; i++) {
            data[i] = registerDataItMap.data[registerDataItMap.keys[i]].data;
        }

        return data;
    }

    /// @notice Return matched registered data with NFT address and token ID
    /// @param nftAddress NFT address
    /// @param tokenId token ID
    /// @return Matched registered data
    function getRegisterData(address nftAddress, uint256 tokenId)
        public
        view
        returns (registerDataIterableMap.registerData memory)
    {
        return registerDataItMap.getByNFT(nftAddress, tokenId);
    }

    /// @notice Warning: This function will delete all registered NFT data.
    function removeAllRegisterData() public onlyOwner {
        for (uint256 i = 0; i < registerDataItMap.keys.length; i++) {
            delete registerDataItMap.data[registerDataItMap.keys[i]];
        }

        delete registerDataItMap.keys;
    }

    //--------------------------------------------------------------------------
    // NFT REQUEST/ACCEPT/CHANGE/UNREGISTER FUNCTION
    //--------------------------------------------------------------------------

    /// @notice Request register NFT
    /// @param nftAddress NFT address
    /// @param tokenId NFT token ID
    function requestRegisterNFT(address nftAddress, uint256 tokenId) public {
        // 1. Check the duplicate element in request data.
        require(requestDataItMap.contains(nftAddress, tokenId) == false, "RM1");

        // 2. Check the duplicate element in register data.
        require(
            registerDataItMap.contains(nftAddress, tokenId) == false,
            "RM2"
        );

        // 3. Check NFT owner is same as msg.sender.
        address ownerAddress = getNFTOwner(nftAddress, tokenId);
        require(ownerAddress == msg.sender, "RM4");

        // 4. Add registerDataItMap.
        requestDataItMap.insert(nftAddress, tokenId);

        // 5. Emit RequestRegisterNFT event.
        emit RequestRegisterNFT(nftAddress, tokenId, ownerAddress);
    }

    /// @notice Accept request register NFT
    /// @param nftAddress NFT address
    /// @param tokenId NFT token ID
    function acceptRegisterNFT(address nftAddress, uint256 tokenId)
        public
        onlyOwner
    {
        // 1. Check the containing element in request data.
        require(requestDataItMap.contains(nftAddress, tokenId) == true, "RM1");

        // 2. Check the duplicate element in register data.
        require(
            registerDataItMap.contains(nftAddress, tokenId) == false,
            "RM2"
        );

        // 3. Add registerDataItMap with default fee and duration value.
        // Default feeTokenAddress and rentFeeByToken to be zero.
        registerDataItMap.insert(
            nftAddress,
            tokenId,
            RENT_FEE,
            address(0),
            0,
            RENT_DURATION
        );

        // 4. Remove request data.
        requestDataItMap.remove(nftAddress, tokenId);

        // 5. Emit AcceptRegisterNFT event.
        address ownerAddress = getNFTOwner(nftAddress, tokenId);
        emit AcceptRegisterNFT(
            nftAddress,
            tokenId,
            RENT_FEE,
            RENT_DURATION,
            ownerAddress
        );
    }

    /// @notice Change NFT data
    /// @param nftAddress NFT address
    /// @param tokenId NFT token ID
    /// @param rentFee rent fee
    /// @param feeTokenAddress fee token address
    /// @param rentFeeByToken rent fee by token
    /// @param rentDuration rent duration
    // TODO : Restrict feeTokenAddress by pre-registerd address data.
    function changeNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        uint256 rentDuration
    ) public {
        // 1. Check NFT owner or rentMarket owner is same as msg.sender.
        address ownerAddress = getNFTOwner(nftAddress, tokenId);
        require(msg.sender == ownerAddress || msg.sender == owner(), "RM5");

        // 2. Check the duplicate element.
        require(registerDataItMap.contains(nftAddress, tokenId) == true, "RM3");

        // 3. Get data.
        registerDataIterableMap.registerData memory data = registerDataItMap
            .getByNFT(nftAddress, tokenId);

        // 4. Change registerDataItMap.
        registerDataItMap.set(
            nftAddress,
            tokenId,
            rentFee,
            feeTokenAddress,
            rentFeeByToken,
            rentDuration
        );

        // 5. Emit ChangeNFT event.
        emit ChangeNFT(
            data.nftAddress,
            data.tokenId,
            rentFee,
            feeTokenAddress,
            rentFeeByToken,
            rentDuration,
            ownerAddress,
            msg.sender
        );
    }

    /// @notice Unrequest NFT data
    /// @param nftAddress NFT address
    /// @param tokenId NFT token ID
    function unrequestNFT(address nftAddress, uint256 tokenId) public {
        // 1. Check NFT owner or rentMarket owner is same as msg.sender.
        address ownerAddress = getNFTOwner(nftAddress, tokenId);
        require(msg.sender == ownerAddress || msg.sender == owner(), "RM5");

        // 2. Check the duplicate element.
        require(requestDataItMap.contains(nftAddress, tokenId) == true, "RM3");

        // 3. Get data.
        requestDataIterableMap.requestData memory data = requestDataItMap
            .getByNFT(nftAddress, tokenId);

        // 4. Delete requestDataItMap.
        requestDataItMap.remove(nftAddress, tokenId);

        // 5. Emit UnrequestNFT event.
        emit UnrequestNFT(
            data.nftAddress,
            data.tokenId,
            ownerAddress,
            msg.sender
        );
    }

    /// @notice Unregister NFT data
    /// @param nftAddress NFT address
    /// @param tokenId NFT token ID
    function unregisterNFT(address nftAddress, uint256 tokenId) public {
        // 1. Check NFT owner or rentMarket owner is same as msg.sender.
        address ownerAddress = getNFTOwner(nftAddress, tokenId);
        require(msg.sender == ownerAddress || msg.sender == owner(), "RM5");

        // 2. Check the duplicate element.
        require(registerDataItMap.contains(nftAddress, tokenId) == true, "RM3");

        // 3. Get data.
        registerDataIterableMap.registerData memory data = registerDataItMap
            .getByNFT(nftAddress, tokenId);

        // 4. Delete registerDataItMap.
        registerDataItMap.remove(nftAddress, tokenId);

        // 5. Emit UnregisterNFT event.
        emit UnregisterNFT(
            data.nftAddress,
            data.tokenId,
            data.rentFee,
            data.feeTokenAddress,
            data.rentFeeByToken,
            data.rentDuration,
            ownerAddress,
            msg.sender
        );
    }

    //--------------------------------------------------------------------------
    //---------------------------------- RENT FLOW -----------------------------
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // RENT EVENT
    //--------------------------------------------------------------------------

    // Declare rent NFT event.
    event RentNFT(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        bool isRentByToken,
        uint256 rentDuration,
        address renterAddress,
        address indexed renteeAddress,
        address serviceAddress,
        uint256 rentStartBlock
    );

    // Declare unrent NFT event.
    event UnrentNFT(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        bool isRentByToken,
        uint256 rentDuration,
        address renterAddress,
        address indexed renteeAddress,
        address serviceAddress,
        uint256 rentStartBlock
    );

    //--------------------------------------------------------------------------
    // RENT GET/REMOVE FUNCTION
    //--------------------------------------------------------------------------

    /// @notice Return the all rented NFT data.
    /// @return All rented NFT data array.
    function getAllRentData()
        public
        view
        returns (rentDataIterableMap.rentData[] memory)
    {
        rentDataIterableMap.rentData[]
            memory data = new rentDataIterableMap.rentData[](
                rentDataItMap.keys.length
            );

        for (uint256 i = 0; i < rentDataItMap.keys.length; i++) {
            data[i] = rentDataItMap.data[rentDataItMap.keys[i]].data;
        }

        return data;
    }

    /// @notice Return matched rented data with NFT address and token ID
    /// @param nftAddress NFT address
    /// @param tokenId token ID
    /// @return Matched rented data
    function getRentData(address nftAddress, uint256 tokenId)
        public
        view
        returns (rentDataIterableMap.rentData memory)
    {
        return rentDataItMap.getByNFT(nftAddress, tokenId);
    }

    /// @notice Warning: This function will delete all rented NFT data.
    function removeAllRentData() public onlyOwner {
        for (uint256 i = 0; i < rentDataItMap.keys.length; i++) {
            delete rentDataItMap.data[rentDataItMap.keys[i]];
        }

        delete rentDataItMap.keys;
    }

    //--------------------------------------------------------------------------
    // RENT RENT/RENTBYTOKEN/UNRENT FUNCTION
    //--------------------------------------------------------------------------

    /// @notice Rent NFT
    /// @param nftAddress NFT address
    /// @param tokenId NFT token ID
    /// @param serviceAddress service address
    function rentNFT(
        address nftAddress,
        uint256 tokenId,
        address serviceAddress
    ) public payable {
        // 1. Check the nftAddress and tokenId containing in register NFT data.
        require(registerDataItMap.contains(nftAddress, tokenId) == true, "RM7");

        // 2. Check the service address containing in service data.
        require(serviceItMap.contains(serviceAddress) == true, "RM6");

        // 3. Check the nftAddress and tokenId containing in rent NFT data.
        require(rentDataItMap.contains(nftAddress, tokenId) == false, "RM9");

        // 4. Check rent fee is not same as rentFee.
        // msg.value is on wei unit.
        require(
            registerDataItMap.getByNFT(nftAddress, tokenId).rentFee ==
                msg.value,
            "RM8"
        );

        // 5. Get data.
        address ownerAddress = getNFTOwner(nftAddress, tokenId);
        registerDataIterableMap.registerData memory data = registerDataItMap
            .getByNFT(nftAddress, tokenId);

        // 6. Add rentDataItMap.
        // Set isRentByToken to be false.
        rentDataItMap.insert(
            nftAddress,
            tokenId,
            data.rentFee,
            data.feeTokenAddress,
            data.rentFeeByToken,
            false,
            data.rentDuration,
            ownerAddress,
            msg.sender,
            serviceAddress,
            block.number
        );

        // 7. Add pendingRentFeeMap.
        pendingRentFeeMap.insert(
            ownerAddress,
            serviceAddress,
            address(0),
            msg.value
        );

        // 8. Emit RentNFT event.
        emit RentNFT(
            nftAddress,
            tokenId,
            data.rentFee,
            data.feeTokenAddress,
            data.rentFeeByToken,
            false,
            data.rentDuration,
            ownerAddress,
            msg.sender,
            serviceAddress,
            block.number
        );
    }

    /// @notice Rent NFT by token
    /// @param nftAddress NFT address
    /// @param tokenId NFT token ID
    /// @param serviceAddress service address
    function rentNFTByToken(
        address nftAddress,
        uint256 tokenId,
        address serviceAddress
    ) public payable {
        // 1. Check the nftAddress and tokenId containing in register NFT data.
        require(registerDataItMap.contains(nftAddress, tokenId) == true, "RM7");
        // 2. Check the service address containing in service data.
        require(serviceItMap.contains(serviceAddress) == true, "RM6");
        // 3. Check the nftAddress and tokenId containing in rent NFT data.
        require(rentDataItMap.contains(nftAddress, tokenId) == false, "RM9");
        // 4. In case of erc20 payment, msg.value should zero.
        require(msg.value == 0, "RM13");
        // 5. Get data.
        address ownerAddress = getNFTOwner(nftAddress, tokenId);
        registerDataIterableMap.registerData memory data = registerDataItMap
            .getByNFT(nftAddress, tokenId);
        // 6. Send erc20 token to rentMarket contract
        IERC20(data.feeTokenAddress).transferFrom(
            msg.sender,
            address(this),
            data.rentFeeByToken
        );
        // 7. Add rentDataItMap.
        // Set isRentByToken to be true.
        rentDataItMap.insert(
            nftAddress,
            tokenId,
            data.rentFee,
            data.feeTokenAddress,
            data.rentFeeByToken,
            true,
            data.rentDuration,
            ownerAddress,
            msg.sender,
            serviceAddress,
            block.number
        );
        // 8. Add pendingRentFeeMap.
        pendingRentFeeMap.insert(
            ownerAddress,
            serviceAddress,
            data.feeTokenAddress,
            data.rentFeeByToken
        );
        // 8. Emit RentNFT event.
        emit RentNFT(
            nftAddress,
            tokenId,
            data.rentFee,
            data.feeTokenAddress,
            data.rentFeeByToken,
            true,
            data.rentDuration,
            ownerAddress,
            msg.sender,
            serviceAddress,
            block.number
        );
    }

    /// @notice Unrent NFT
    /// @param nftAddress NFT address
    /// @param tokenId NFT token ID
    function unrentNFT(address nftAddress, uint256 tokenId) public {
        uint256 usedAmount = 0;
        uint256 unusedAmount = 0;
        uint256 rentFee = 0;
        uint256 amount = 0;

        // 1. Check the duplicate element.
        require(rentDataItMap.contains(nftAddress, tokenId) == true, "RM10");

        // 2. Check msg.sender is same as renteeAddress.
        require(
            rentDataItMap.getByNFT(nftAddress, tokenId).renteeAddress ==
                msg.sender,
            "RM11"
        );

        rentDataIterableMap.rentData memory data = rentDataItMap.getByNFT(
            nftAddress,
            tokenId
        );

        if (data.isRentByToken == true) {
            rentFee = data.rentFeeByToken;
        } else {
            rentFee = data.rentFee;
        }

        // 3. If duration is not finished, refund to rentee.
        if (
            block.number > data.rentStartBlock &&
            data.rentStartBlock + data.rentDuration > block.number
        ) {
            // Calculate remain block number.
            uint256 usedBlockDiff = block.number - data.rentStartBlock;

            // Calculate refund amount.
            usedAmount = SafeMath.div(
                rentFee * usedBlockDiff,
                data.rentDuration
            );
            unusedAmount = SafeMath.sub(rentFee, usedAmount);

            // Transfer refund.
            amount = accountBalanceItMap.getAmount(
                data.renteeAddress,
                data.feeTokenAddress
            );
            accountBalanceItMap.insert(
                data.renteeAddress,
                data.feeTokenAddress,
                amount + unusedAmount
            );
        }

        if (usedAmount > 0) {
            // Calculate remain fee amount.
            uint256 renterShare = SafeMath.div(
                usedAmount * RENTER_FEE_QUOTA,
                100
            );
            uint256 serviceShare = SafeMath.div(
                usedAmount * SERVICE_FEE_QUOTA,
                100
            );
            uint256 marketShare = usedAmount - renterShare - serviceShare;

            // Calculate and save each party amount as each share.
            // Get renter(NFT owner) share.
            amount = accountBalanceItMap.getAmount(
                data.renterAddress,
                data.feeTokenAddress
            );
            accountBalanceItMap.insert(
                data.renterAddress,
                data.feeTokenAddress,
                amount + renterShare
            );

            // Get service share.
            amount = accountBalanceItMap.getAmount(
                data.serviceAddress,
                data.feeTokenAddress
            );
            accountBalanceItMap.insert(
                data.serviceAddress,
                data.feeTokenAddress,
                amount + serviceShare
            );

            // Get market share.
            amount = accountBalanceItMap.getAmount(
                MARKET_SHARE_ADDRESS,
                data.feeTokenAddress
            );
            accountBalanceItMap.insert(
                MARKET_SHARE_ADDRESS,
                data.feeTokenAddress,
                amount + marketShare
            );
        }

        // 4. Remove rentDataItMap.
        // For avoiding error.
        // compilerError: Stack too deep, try removing local variables.
        rentDataIterableMap.rentData memory eventData = rentDataItMap.getByNFT(
            nftAddress,
            tokenId
        );
        rentDataItMap.remove(nftAddress, tokenId);

        // 5. Emit UnrentNFT event.
        emit UnrentNFT(
            eventData.nftAddress,
            eventData.tokenId,
            eventData.rentFee,
            eventData.feeTokenAddress,
            eventData.rentFeeByToken,
            eventData.isRentByToken,
            eventData.rentDuration,
            eventData.renterAddress,
            eventData.renteeAddress,
            eventData.serviceAddress,
            eventData.rentStartBlock
        );
    }

    //--------------------------------------------------------------------------
    //---------------------------------- SETTLE FLOW ---------------------------
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // SETTLE EVENT
    //--------------------------------------------------------------------------

    // Declare settle rent data event.
    event SettleRentData(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        bool isRentByToken,
        uint256 rentDuration,
        address renterAddress,
        address indexed renteeAddress,
        address serviceAddress,
        uint256 rentStartBlock
    );

    //--------------------------------------------------------------------------
    // SETTLE SETTLE FUNCTION
    //--------------------------------------------------------------------------

    /// @notice Settle all the rent-duration-finished data and transfer rent fee to owner and others.
    function settleRentData() public onlyOwner {
        for (uint256 i = 0; i < rentDataItMap.keys.length; i++) {
            rentDataIterableMap.rentData memory data = rentDataItMap
                .data[rentDataItMap.keys[i]]
                .data;

            if (block.number > data.rentStartBlock + data.rentDuration) {
                // 1. Find the should-be-removed-from-rent element.
                // rent duration is finished.

                // 2. Transfer rent fee to the owner of NFT.
                uint256 amountRentFee = pendingRentFeeMap.getAmount(
                    data.renterAddress,
                    data.serviceAddress,
                    data.feeTokenAddress
                );

                // https://fravoll.github.io/solidity-patterns/secure_ether_transfer.html
                // send, call.value, and transer
                // Split as defined proportion.

                // Calculate each party share as each quota.
                uint256 renterShare = SafeMath.div(
                    amountRentFee * RENTER_FEE_QUOTA,
                    100
                );
                uint256 serviceShare = SafeMath.div(
                    amountRentFee * SERVICE_FEE_QUOTA,
                    100
                );
                uint256 marketShare = amountRentFee -
                    renterShare -
                    serviceShare;

                // Calculate and save each party amount as each share.
                // Get renter(NFT owner) share.
                uint256 amount = accountBalanceItMap.getAmount(
                    data.renterAddress,
                    data.feeTokenAddress
                );
                accountBalanceItMap.insert(
                    data.renterAddress,
                    data.feeTokenAddress,
                    amount + renterShare
                );

                // Get service share.
                amount = accountBalanceItMap.getAmount(
                    data.serviceAddress,
                    data.feeTokenAddress
                );
                accountBalanceItMap.insert(
                    data.serviceAddress,
                    data.feeTokenAddress,
                    amount + serviceShare
                );

                // Get market share.
                amount = accountBalanceItMap.getAmount(
                    MARKET_SHARE_ADDRESS,
                    data.feeTokenAddress
                );
                accountBalanceItMap.insert(
                    MARKET_SHARE_ADDRESS,
                    data.feeTokenAddress,
                    amount + marketShare
                );

                // 3. Remove pendingRentFeeMap and rentDataItMap.
                pendingRentFeeMap.remove(
                    data.renterAddress,
                    data.serviceAddress,
                    data.feeTokenAddress
                );
                // For avoiding error.
                // compilerError: Stack too deep, try removing local variables.
                rentDataIterableMap.rentData memory eventData = rentDataItMap
                    .data[rentDataItMap.keys[i]]
                    .data;
                rentDataItMap.remove(data.nftAddress, data.tokenId);

                // 4. Emit SettleRentData event.
                emit SettleRentData(
                    eventData.nftAddress,
                    eventData.tokenId,
                    eventData.rentFee,
                    eventData.feeTokenAddress,
                    eventData.rentFeeByToken,
                    eventData.isRentByToken,
                    eventData.rentDuration,
                    eventData.renterAddress,
                    eventData.renteeAddress,
                    eventData.serviceAddress,
                    eventData.rentStartBlock
                );
            }
        }
    }

    //--------------------------------------------------------------------------
    //---------------------------------- WITHDRAW FLOW -------------------------
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // WITHDRAW EVENT
    //--------------------------------------------------------------------------

    event WithdrawMyBalance(
        address requester,
        address indexed recipient,
        address indexed tokenAddress,
        uint256 indexed amount
    );

    //--------------------------------------------------------------------------
    // WITHDRAW WITHDRAW FUNCTION
    //--------------------------------------------------------------------------

    function withdrawMyBalance(address recipient, address tokenAddress)
        public
        payable
    {
        // Get amount from account balance.
        uint256 amount = accountBalanceItMap.getAmount(
            msg.sender,
            tokenAddress
        );

        // Withdraw amount, if any.
        if (amount > 0) {
            if (tokenAddress == address(0)) {
                (bool sent, ) = recipient.call{value: amount}("");
                require(sent, "RM14");
            } else {
                IERC20(tokenAddress).approve(address(this), amount);
                IERC20(tokenAddress).transferFrom(
                    address(this),
                    recipient,
                    amount
                );
            }

            accountBalanceItMap.remove(msg.sender, tokenAddress);

            emit WithdrawMyBalance(msg.sender, recipient, tokenAddress, amount);
        }
    }

    //--------------------------------------------------------------------------
    // UTILITY FUNCTION
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // MARKET_ADDRESS GET/SET FUNCTION
    //--------------------------------------------------------------------------

    function getMarketShareAddress()
        public
        view
        returns (address shareAddress)
    {
        return MARKET_SHARE_ADDRESS;
    }

    function setMarketShareAddress(address shareAddress) public onlyOwner {
        MARKET_SHARE_ADDRESS = shareAddress;
    }

    //--------------------------------------------------------------------------
    // BALANCE GET FUNCTION
    //--------------------------------------------------------------------------

    function getMyBalance(address tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        return accountBalanceItMap.getAmount(msg.sender, tokenAddress);
    }

    //--------------------------------------------------------------------------
    // QUOTA GET/SET FUNCTION
    //--------------------------------------------------------------------------

    function getFeeQuota()
        public
        view
        returns (
            uint256 renterFeeQuota,
            uint256 serviceFeeQuota,
            uint256 marketFeeQuota
        )
    {
        return (RENTER_FEE_QUOTA, SERVICE_FEE_QUOTA, MARKET_FEE_QUOTA);
    }

    function setFeeQuota(
        uint256 renterFeeQuota,
        uint256 serviceFeeQuota,
        uint256 marketFeeQuota
    ) public onlyOwner {
        // 1. Sum should be 100.
        require(
            renterFeeQuota + serviceFeeQuota + marketFeeQuota == 100,
            "RM12"
        );

        // 2. Set each quota.
        RENTER_FEE_QUOTA = renterFeeQuota;
        SERVICE_FEE_QUOTA = serviceFeeQuota;
        MARKET_FEE_QUOTA = marketFeeQuota;
    }

    function getNFTOwner(address nftAddress, uint256 tokenId)
        private
        returns (address)
    {
        bool response;
        bytes memory responseData;

        // Get the owner address of NFT with token ID.
        (response, responseData) = nftAddress.call(
            abi.encodeWithSignature("ownerOf(uint256)", tokenId)
        );

        // TODO : Handle response false case - revert?.
        console.log("response: ", response);
        // Check sender address is same as owner address of NFT.
        return abi.decode(responseData, (address));
    }
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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// This code has not been professionally audited,
// therefore we cannot make any promises about
// safety or correctness. Use at own risk.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Strings.sol";

// Examples for iterable mapping.
//
// https://medium.com/rayonprotocol/iteration-%EA%B0%80%EB%8A%A5%ED%95%9C-mapping-%EC%9D%84-%EA%B0%80%EC%A7%80%EB%8A%94-%EC%8A%A4%EB%A7%88%ED%8A%B8-%EC%BB%A8%ED%8A%B8%EB%9E%99%ED%8A%B8-%EC%9E%91%EC%84%B1-7974eae80f2d
// https://github.com/szerintedmi/solidity-itMapsLib/blob/master/itMapsLib.sol
// https://medium.com/rayonprotocol/creating-a-smart-contract-having-iterable-mapping-9b117a461115
// https://docs.soliditylang.org/en/develop/types.html?highlight=push#arrays

library pendingRentFeeIterableMap {
    struct pendingRentFee {
        address renterAddress;
        address serviceAddress;
        address feeTokenAddress;
        uint256 amount;
    }

    // uint256 maximum value.
    // https://ethereum.stackexchange.com/questions/58981/what-is-the-maximum-value-an-int-and-uint-can-store
    struct pendingRentFeeEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        pendingRentFee data;
    }

    struct pendingRentFeeMap {
        mapping(string => pendingRentFeeEntry) data;
        string[] keys;
    }

    function encodeKey(
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public pure returns (string memory) {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(renterAddress)), 20),
                Strings.toHexString(uint256(uint160(serviceAddress)), 20),
                Strings.toHexString(uint256(uint160(feeTokenAddress)), 20)
            )
        );

        return keyString;
    }

    function decodeKey(pendingRentFeeMap storage self, string memory key)
        public
        view
        returns (
            address renterAddress,
            address serviceAddress,
            address feeTokenAddress
        )
    {
        pendingRentFeeEntry memory e = self.data[key];

        return (
            e.data.renterAddress,
            e.data.serviceAddress,
            e.data.feeTokenAddress
        );
    }

    function insert(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress,
        uint256 amount
    ) public returns (bool replaced) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        pendingRentFeeEntry storage e = self.data[key];

        if (e.idx > 0) {
            return true;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.renterAddress = renterAddress;
            e.data.serviceAddress = serviceAddress;
            e.data.feeTokenAddress = feeTokenAddress;
            e.data.amount = amount;

            return false;
        }
    }

    function remove(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public returns (bool success) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        pendingRentFeeEntry storage e = self.data[key];

        // Check if entry not exist.
        require(e.idx != 0);
        // Check if invalid idx value.
        require(e.idx <= self.keys.length);

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public view returns (bool exists) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        return self.data[key].idx > 0;
    }

    function size(pendingRentFeeMap storage self)
        public
        view
        returns (uint256)
    {
        return self.keys.length;
    }

    function getAmount(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public view returns (uint256) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        return self.data[key].data.amount;
    }

    function getByAddress(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public view returns (pendingRentFee memory) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        return self.data[key].data;
    }

    function getKeyByIndex(pendingRentFeeMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(pendingRentFeeMap storage self, uint256 idx)
        public
        view
        returns (pendingRentFee memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library accountBalanceIterableMap {
    struct accountBalance {
        address accountAddress;
        address tokenAddress;
        uint256 amount;
    }

    // uint256 maximum value.
    // https://ethereum.stackexchange.com/questions/58981/what-is-the-maximum-value-an-int-and-uint-can-store
    struct accountBalanceEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        accountBalance data;
    }

    struct accountBalanceMap {
        mapping(string => accountBalanceEntry) data;
        string[] keys;
    }

    function encodeKey(address accountAddress, address tokenAddress)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(accountAddress)), 20),
                Strings.toHexString(uint256(uint160(tokenAddress)), 20)
            )
        );

        return keyString;
    }

    function decodeKey(accountBalanceMap storage self, string memory key)
        public
        view
        returns (address accountAddress, address tokenAddress)
    {
        accountBalanceEntry memory e = self.data[key];

        return (e.data.accountAddress, e.data.tokenAddress);
    }

    function insert(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress,
        uint256 amount
    ) public returns (bool replaced) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        accountBalanceEntry storage e = self.data[key];

        if (e.idx > 0) {
            return true;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.accountAddress = accountAddress;
            e.data.tokenAddress = tokenAddress;
            e.data.amount = amount;

            return false;
        }
    }

    function remove(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress
    ) public returns (bool success) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        accountBalanceEntry storage e = self.data[key];

        // Check if entry not exist.
        require(e.idx != 0);
        // Check if invalid idx value.
        require(e.idx <= self.keys.length);

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress
    ) public view returns (bool exists) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        return self.data[key].idx > 0;
    }

    function size(accountBalanceMap storage self)
        public
        view
        returns (uint256)
    {
        return self.keys.length;
    }

    function getAmount(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress
    ) public view returns (uint256) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        return self.data[key].data.amount;
    }

    function getByAddress(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress
    ) public view returns (accountBalance memory) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        return self.data[key].data;
    }

    function getKeyByIndex(accountBalanceMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(accountBalanceMap storage self, uint256 idx)
        public
        view
        returns (accountBalance memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library tokenDataIterableMap {
    struct tokenData {
        address tokenAddress;
        string name;
    }

    // uint256 maximum value.
    // https://ethereum.stackexchange.com/questions/58981/what-is-the-maximum-value-an-int-and-uint-can-store
    struct tokenDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        tokenData data;
    }

    struct tokenDataMap {
        mapping(string => tokenDataEntry) data;
        string[] keys;
    }

    function encodeKey(address tokenAddress)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(tokenAddress)), 20)
            )
        );

        return keyString;
    }

    function decodeKey(tokenDataMap storage self, string memory key)
        public
        view
        returns (address tokenAddress)
    {
        tokenDataEntry memory e = self.data[key];

        return e.data.tokenAddress;
    }

    function insert(
        tokenDataMap storage self,
        address tokenAddress,
        string memory name
    ) public returns (bool replaced) {
        string memory key = encodeKey(tokenAddress);
        tokenDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return true;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.tokenAddress = tokenAddress;
            e.data.name = name;

            return false;
        }
    }

    function remove(tokenDataMap storage self, address tokenAddress)
        public
        returns (bool success)
    {
        string memory key = encodeKey(tokenAddress);
        tokenDataEntry storage e = self.data[key];

        // Check if entry not exist.
        require(e.idx != 0);
        // Check if invalid idx value.
        require(e.idx <= self.keys.length);

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(tokenDataMap storage self, address tokenAddress)
        public
        view
        returns (bool exists)
    {
        string memory key = encodeKey(tokenAddress);
        return self.data[key].idx > 0;
    }

    function size(tokenDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getName(tokenDataMap storage self, address tokenAddress)
        public
        view
        returns (string memory)
    {
        string memory key = encodeKey(tokenAddress);
        return self.data[key].data.name;
    }

    function getByAddress(tokenDataMap storage self, address tokenAddress)
        public
        view
        returns (tokenData memory)
    {
        string memory key = encodeKey(tokenAddress);
        return self.data[key].data;
    }

    function getKeyByIndex(tokenDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(tokenDataMap storage self, uint256 idx)
        public
        view
        returns (tokenData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library serviceDataIterableMap {
    struct serviceData {
        address serviceAddress;
        string name;
    }

    // uint256 maximum value.
    // https://ethereum.stackexchange.com/questions/58981/what-is-the-maximum-value-an-int-and-uint-can-store
    struct serviceDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        serviceData data;
    }

    struct serviceDataMap {
        mapping(string => serviceDataEntry) data;
        string[] keys;
    }

    function encodeKey(address serviceAddress)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(serviceAddress)), 20)
            )
        );

        return keyString;
    }

    function decodeKey(serviceDataMap storage self, string memory key)
        public
        view
        returns (address serviceAddress)
    {
        serviceDataEntry memory e = self.data[key];

        return e.data.serviceAddress;
    }

    function insert(
        serviceDataMap storage self,
        address serviceAddress,
        string memory name
    ) public returns (bool replaced) {
        string memory key = encodeKey(serviceAddress);
        serviceDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return true;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.serviceAddress = serviceAddress;
            e.data.name = name;

            return false;
        }
    }

    function remove(serviceDataMap storage self, address serviceAddress)
        public
        returns (bool success)
    {
        string memory key = encodeKey(serviceAddress);
        serviceDataEntry storage e = self.data[key];

        // Check if entry not exist.
        require(e.idx != 0);
        // Check if invalid idx value.
        require(e.idx <= self.keys.length);

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(serviceDataMap storage self, address serviceAddress)
        public
        view
        returns (bool exists)
    {
        string memory key = encodeKey(serviceAddress);
        return self.data[key].idx > 0;
    }

    function size(serviceDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getName(serviceDataMap storage self, address serviceAddress)
        public
        view
        returns (string memory)
    {
        string memory key = encodeKey(serviceAddress);
        return self.data[key].data.name;
    }

    function getByAddress(serviceDataMap storage self, address serviceAddress)
        public
        view
        returns (serviceData memory)
    {
        string memory key = encodeKey(serviceAddress);
        return self.data[key].data;
    }

    function getKeyByIndex(serviceDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(serviceDataMap storage self, uint256 idx)
        public
        view
        returns (serviceData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library requestDataIterableMap {
    struct requestData {
        address nftAddress;
        uint256 tokenId;
    }

    // uint256 maximum value.
    // https://ethereum.stackexchange.com/questions/58981/what-is-the-maximum-value-an-int-and-uint-can-store
    struct requestDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        requestData data;
    }

    struct requestDataMap {
        mapping(string => requestDataEntry) data;
        string[] keys;
    }

    function encodeKey(address nftAddress, uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(nftAddress)), 20),
                Strings.toString(tokenId)
            )
        );

        return keyString;
    }

    function decodeKey(requestDataMap storage self, string memory key)
        public
        view
        returns (address nftAddress, uint256 tokenId)
    {
        requestDataEntry memory e = self.data[key];

        return (e.data.nftAddress, e.data.tokenId);
    }

    function insert(
        requestDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public returns (bool replaced) {
        string memory key = encodeKey(nftAddress, tokenId);
        requestDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return true;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.nftAddress = nftAddress;
            e.data.tokenId = tokenId;

            return false;
        }
    }

    function remove(
        requestDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        requestDataEntry storage e = self.data[key];

        // Check if entry not exist.
        require(e.idx != 0);
        // Check if invalid idx value.
        require(e.idx <= self.keys.length);

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        requestDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (bool exists) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].idx > 0;
    }

    function size(requestDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getByNFT(
        requestDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (requestData memory) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].data;
    }

    function getKeyByIndex(requestDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(requestDataMap storage self, uint256 idx)
        public
        view
        returns (requestData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library registerDataIterableMap {
    struct registerData {
        address nftAddress;
        uint256 tokenId;
        uint256 rentFee;
        address feeTokenAddress;
        uint256 rentFeeByToken;
        uint256 rentDuration;
    }

    // uint256 maximum value.
    // https://ethereum.stackexchange.com/questions/58981/what-is-the-maximum-value-an-int-and-uint-can-store
    struct registerDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        registerData data;
    }

    struct registerDataMap {
        mapping(string => registerDataEntry) data;
        string[] keys;
    }

    function encodeKey(address nftAddress, uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(nftAddress)), 20),
                Strings.toString(tokenId)
            )
        );

        return keyString;
    }

    function decodeKey(registerDataMap storage self, string memory key)
        public
        view
        returns (address nftAddress, uint256 tokenId)
    {
        registerDataEntry memory e = self.data[key];

        return (e.data.nftAddress, e.data.tokenId);
    }

    function insert(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        uint256 rentDuration
    ) public returns (bool replaced) {
        string memory key = encodeKey(nftAddress, tokenId);
        registerDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return true;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.nftAddress = nftAddress;
            e.data.tokenId = tokenId;
            e.data.rentFee = rentFee;
            e.data.feeTokenAddress = feeTokenAddress;
            e.data.rentFeeByToken = rentFeeByToken;
            e.data.rentDuration = rentDuration;

            return false;
        }
    }

    function set(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        uint256 rentDuration
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        registerDataEntry storage e = self.data[key];

        // Check if entry not exist.
        require(e.idx != 0);
        // Check if invalid idx value.
        require(e.idx <= self.keys.length);

        // Set data.
        e.data.rentFee = rentFee;
        e.data.feeTokenAddress = feeTokenAddress;
        e.data.rentFeeByToken = rentFeeByToken;
        e.data.rentDuration = rentDuration;

        return true;
    }

    function remove(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        registerDataEntry storage e = self.data[key];

        // Check if entry not exist.
        require(e.idx != 0);
        // Check if invalid idx value.
        require(e.idx <= self.keys.length);

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (bool exists) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].idx > 0;
    }

    function size(registerDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getByNFT(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (registerData memory) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].data;
    }

    function getKeyByIndex(registerDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(registerDataMap storage self, uint256 idx)
        public
        view
        returns (registerData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library rentDataIterableMap {
    struct rentData {
        address nftAddress;
        uint256 tokenId;
        uint256 rentFee;
        address feeTokenAddress;
        uint256 rentFeeByToken;
        bool isRentByToken;
        uint256 rentDuration;
        address renterAddress;
        address renteeAddress;
        address serviceAddress;
        uint256 rentStartBlock;
    }

    // uint256 maximum value.
    // https://ethereum.stackexchange.com/questions/58981/what-is-the-maximum-value-an-int-and-uint-can-store
    struct rentDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        rentData data;
    }

    struct rentDataMap {
        mapping(string => rentDataEntry) data;
        string[] keys;
    }

    function encodeKey(address nftAddress, uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(nftAddress)), 20),
                Strings.toString(tokenId)
            )
        );

        return keyString;
    }

    function decodeKey(rentDataMap storage self, string memory key)
        public
        view
        returns (address nftAddress, uint256 tokenId)
    {
        rentDataEntry memory e = self.data[key];

        return (e.data.nftAddress, e.data.tokenId);
    }

    function insert(
        rentDataMap storage self,
        address nftAddress,
        uint256 tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        bool isRentByToken,
        uint256 rentDuration,
        address renterAddress,
        address renteeAddress,
        address serviceAddress,
        uint256 rentStartBlock
    ) public returns (bool replaced) {
        string memory key = encodeKey(nftAddress, tokenId);
        rentDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return true;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.nftAddress = nftAddress;
            e.data.tokenId = tokenId;
            e.data.rentFee = rentFee;
            e.data.feeTokenAddress = feeTokenAddress;
            e.data.rentFeeByToken = rentFeeByToken;
            e.data.isRentByToken = isRentByToken;
            e.data.rentDuration = rentDuration;
            e.data.renterAddress = renterAddress;
            e.data.renteeAddress = renteeAddress;
            e.data.serviceAddress = serviceAddress;
            e.data.rentStartBlock = rentStartBlock;

            return false;
        }
    }

    function remove(
        rentDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        rentDataEntry storage e = self.data[key];

        // Check if entry not exist.
        require(e.idx != 0);
        // Check if invalid idx value.
        require(e.idx <= self.keys.length);

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        rentDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (bool exists) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].idx > 0;
    }

    function size(rentDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getByNFT(
        rentDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (rentData memory) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].data;
    }

    function getKeyByIndex(rentDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(rentDataMap storage self, uint256 idx)
        public
        view
        returns (rentData memory)
    {
        return self.data[self.keys[idx]].data;
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