// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts_token/token/ERC1155/ERC1155.sol";
import "../contracts_token/token/ERC20/IERC20.sol";
import "../contracts_token/token/ERC20/ERC20.sol";
import "../contracts_token/utils/math/SafeMath.sol";
import "../contracts_token/token/ERC1155/IERC1155Receiver.sol";

// Owned contract
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract NFTMarketPlace is ERC1155, Owned{
    using SafeMath for uint; 
    uint256 public counter = 1;
    string public name;
    string public symbol;
    address public platformFeeAccumulatorAddress;
    uint256 public platformFeePercentage;
    uint256 public royaltyPercentage;
    uint public minRentTime;
    uint256[] public index;
    address public admin; 

    enum TypeOfNFT
    {
      RWO,
      PDR
    } 

    struct baseNFT{
        bool exists;
        uint index;
        address originalOwner;
        string location;
        uint initialAvailableDate;
        uint amountPerNFT;
        uint noOfCopies;
        TypeOfNFT typeOfNFT;
    }

    struct RentalTokenRights {
        bool canBurn;
        bool canTransferToAll;
        bool canTransferToPreapproved;
        bool canCopyAcrossRights;
    }

    // mapping for PDR and rwo nfts
    mapping(uint256 => baseNFT) public entries;

    // tokenId -> accounts[] for RWO
    mapping(uint256 => address) internal holdersRWO;
    mapping(uint256 => string) public tokenURIMapping;
    
    // Mapping from token ID to renter address to RentalTokenRights
    mapping (uint => mapping (address => RentalTokenRights)) public renterRights;
    mapping (uint => mapping (address => bool)) public rentalIntention;

    // Mapping from token ID to start time index to rental token owner
    mapping (uint => mapping (uint => address[])) public rentals;

    mapping(uint => address[]) public tokenIdToRenters;

    // Adding mapping to check amount of PDR nft rented by owner : tokenId -> starting_time -> amount to be rented
    mapping(uint => uint) public amountRentalTokenId; 
    mapping (uint => mapping (uint => uint)) public rentalAmount;
    mapping(uint => address) public ownerPDRNFT;
    //address -> tokenId -> time
    mapping (address => mapping (uint => uint)) public balRental;

    // Mapping for preapproved renters
    mapping (uint => mapping (address => bool)) public preapprovedRenters;

    // mapping(tokenId RWO -> [tokenIds PDR]) mapParent
    mapping(uint => uint[]) public mapParent;

    // tokenId(child: PDR) => token owner(parent: RWO)
    mapping(uint => address) public tokenIdToTokenOwner;

    // child address => childId => parent tokenId
    mapping(address => mapping(uint256 => uint256)) public childTokenOwner;
    // (tokenId => endTime)
    mapping(uint => uint) pdrTokenIdToEndTime;

    event PDRNFTAdded(uint256 tokenId, address indexed ownerAddress, string location, uint totalAfter);
    event RWONFTAdded(uint256 tokenId, address indexed ownerAddress, string location, uint totalAfter);

    event MintRental(uint _tokenId, uint _start, uint _end, address indexed _renter);
    event RenewRental(uint _tokenId, uint _start, uint _end);
    event TransferRentalFrom(address indexed _from, address indexed _to, uint _tokenId, uint _start, uint _end);
    event BurnNFT(address indexed _operator,uint _id);
    event BurnNFTByOwner(address indexed _operator,uint _id);

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(balanceOf(msg.sender, _tokenId) > 0);
        _;
    }

    modifier onlyAdminOrOwner() {
        require(owner == msg.sender || admin == msg.sender);
        _;
    }

    constructor(uint _minRentTime) ERC1155() {
        minRentTime = _minRentTime;

        //set deployer as admin
        admin = msg.sender;
        platformFeeAccumulatorAddress = msg.sender;
        platformFeePercentage = 10; //1%
        royaltyPercentage = 10; //1%
    }

    // ERC1155 functions
    function mint(address to, uint256 amount, bytes calldata data, string calldata _uri, bool isPDR) public {
        _mint(to, counter, amount, data); 
        tokenURIMapping[counter] =  _uri;

        // Update the owner of nft mapping
        if(!isPDR){
            holdersRWO[counter] = to;
        }
        counter++;
    }

    // Mint RWO NFTs (only owner or admin)
    function addProperty(
        address _originalOwnerAddress,
        string calldata _advertisementLocation,
        uint _initialAvailableDate,
        uint _amountPerNFT,
        bytes calldata data,
        string calldata _uri, 
        address _erc20Address
    ) public onlyAdminOrOwner{
        ERC20 token = ERC20(_erc20Address);
        require(!entries[counter].exists);
        require(_originalOwnerAddress != address(0x0));
        require(bytes(_advertisementLocation).length > 0);
        require(_amountPerNFT > 0);
        
        require(token.transferFrom(_originalOwnerAddress, address(this),1));
        index.push(counter);
        
        entries[counter] = baseNFT(true, index.length - 1,
                                            _originalOwnerAddress, _advertisementLocation, _initialAvailableDate,
                                            _amountPerNFT,
                                            1,
                                            TypeOfNFT.RWO
                                        );
        
        mint(_originalOwnerAddress, 1, data, _uri, false);
        emit RWONFTAdded(counter, _originalOwnerAddress, _advertisementLocation, index.length);
    }

    // Mint PDR NFTs (only owner or admin)
    function addAdvertisment(
        address _originalOwnerAddress,
        string calldata _advertisementLocation,
        uint _initialAvailableDate,
        uint _amountPerNFT,
        uint256 noOfCopies, 
        bytes calldata data,
        string calldata _uri,
        uint tokenId_RWO,
        address _erc20Address
        
    ) public onlyAdminOrOwner{
        ERC20 token = ERC20(_erc20Address);
        require(!entries[counter].exists);
        require(_originalOwnerAddress != address(0x0));
        require(bytes(_advertisementLocation).length > 0);
        require(_amountPerNFT > 0);

        //TODO: Check this token transfer from
        require(token.transferFrom(_originalOwnerAddress, address(this), noOfCopies));
        index.push(counter);
        
        entries[counter] = baseNFT(true, index.length - 1,
                                                _originalOwnerAddress, _advertisementLocation, _initialAvailableDate,
                                                _amountPerNFT,
                                                noOfCopies,
                                                TypeOfNFT.PDR);

        mapParent[tokenId_RWO].push(counter);
        tokenIdToTokenOwner[counter] = holdersRWO[tokenId_RWO];
        childTokenOwner[holdersRWO[tokenId_RWO]][counter] = tokenId_RWO;

        amountRentalTokenId[counter] = noOfCopies;
            
        mint(_originalOwnerAddress, noOfCopies, data, _uri, true);
        emit PDRNFTAdded(counter, _originalOwnerAddress, _advertisementLocation, index.length);
    }

    function makePayment(address _erc20Address, address _from, address _to, uint _amount) public {
        // erc20 transferFrom
        ERC20 token = ERC20(_erc20Address);
        token.transferFrom(_from, _to, _amount);
    }

    function setNewAdmin(address newAdmin) public onlyOwner{
        admin = newAdmin;
    }

    function setPlatformFeeAccumulatorAddress(address newPlatformFeeAccumulator) public onlyOwner{
        platformFeeAccumulatorAddress = newPlatformFeeAccumulator;
    } 

    // Also for transferring any RWO nft
    function transferRWONFTByOwnerOrAdmin(address from,address to, uint _tokenId, bytes calldata data) public onlyAdminOrOwner{
        transferRWONFT(from, to, _tokenId, data);
    }

    function transferAnyPDRRentalNFT(address _from, address _to, uint _tokenId, uint _start, uint _end, uint _amount, address _erc20Token) public onlyAdminOrOwner{
        uint _startIndex;
        uint _endIndex;
        (_startIndex, _endIndex) = getTimeIndices(_start, _end);
        
        // check availability (for all time slots in range)
        for (uint i = _startIndex; i <= _endIndex; i++) {
            require(rentalAvailable(_tokenId, i));
        }

        copyAcrossRights(_tokenId, _from, _to);
        // check if there is intention to rent, unless we are burning the tokens
        if (_to != address(0x0)) {
            // address ownerRWO = tokenIdToTokenOwner[_tokenId];
            
            require(rentalIntention[_tokenId][_to] == true);

            // charge bondTaken
            baseNFT memory property = entries[_tokenId];
            uint totalPayment = _amount.mul(property.amountPerNFT);

            // Platform Fee: to platformFeeAccumulatorAddress
            makePayment(_erc20Token, _to, platformFeeAccumulatorAddress, (totalPayment.mul(10)).div(100));

            // //Royalities: to owner of RWO owner
            // makePayment(_erc20Token, _to, ownerRWO, (totalPayment.mul(10)).div(100));

            // Crypto payment: to existing rental
            makePayment(_erc20Token, _to, _from, (totalPayment.mul(80)).div(100));
        }

        for (uint256 i = _startIndex; i < _endIndex; i++) {
            (rentals[_tokenId][i]).push(_to);
        }

        emit TransferRentalFrom(_from, _to, _tokenId, _start, _end);
    }

    function burnNFTByOwnerOrAdmin(uint256 id) public onlyAdminOrOwner{
        burnNFT(id);
    }
    
    function burnNFTByTokenOwner(uint256 id)public onlyOwnerOf(id){
        burnNFT(id);
    }

    //burn nfts
    function burnNFT(uint256 id) private{
        baseNFT memory property = entries[id];
        address _owner;

        if((property.typeOfNFT) == TypeOfNFT.PDR){
            // remove rental based mappings
            // multiple owners of same child id - rental
            for(uint i = property.initialAvailableDate; i< pdrTokenIdToEndTime[id]; i++){
                address[] memory _owners = ownerOfRental(id, i);
                for(uint j = 0; j< _owners.length; j++){
                    _burn(_owners[j], id, balanceOf(_owners[j], j));
                    delete renterRights[id][_owners[j]];
                    delete rentalIntention[id][_owners[j]];
                    delete rentals[id][i];
                }
            }
            uint parentId = getRWOTokenIdFromPDRTokenId(id);
            for(uint256 i =0; i< mapParent[parentId].length;i++){
                if (mapParent[parentId][i] == id){
                    delete mapParent[parentId][i];
                    break;
                }
            }
            _owner = tokenIdToTokenOwner[id];
            
            delete childTokenOwner[_owner][id];
            delete ownerPDRNFT[id];

            // remove advertisement minting mappings
            delete tokenIdToTokenOwner[id];
            delete amountRentalTokenId[id];
        } else{
            //burn rwo nft
            _burn(holdersRWO[id], id, balanceOf(holdersRWO[id], id));

            for(uint256 i =0; i<mapParent[id].length;i++){
                //burn pdr nft's
                _burn(holdersRWO[id], mapParent[id][i], balanceOf(holdersRWO[mapParent[id][i]], mapParent[id][i]));

                delete childTokenOwner[holdersRWO[id]][mapParent[id][i]];
                property = entries[i];
                for(uint k = property.initialAvailableDate; k< pdrTokenIdToEndTime[id]; k++){
                address[] memory _owners = ownerOfRental(id, k);
                for(uint j = 0; j< _owners.length; j++){
                    _burn(_owners[j], i, balanceOf(_owners[j], j));
                    delete renterRights[i][_owners[j]];
                    delete rentalIntention[i][_owners[j]];
                    delete rentals[i][k];
                }
            }
        }

        //delete pdr and rwo mapping
        delete mapParent[id];
        delete holdersRWO[id];
        }

        // delete all related nft data
        delete tokenURIMapping[id];
        delete entries[id];
    }

    function getnoOfCopiesPDRNFT(uint256 _pdrTokenId) public view returns(uint256){
        return amountRentalTokenId[_pdrTokenId];
    }

    // pdr token id -> rwo token id
    function getRWOTokenIdFromPDRTokenId(uint256 _pdrTokenId) public view returns(uint256){
        address _owner = tokenIdToTokenOwner[_pdrTokenId];
        return childTokenOwner[_owner][_pdrTokenId];
    }

    // pdr token id -> owner: same as rwo nft owner address
    function getParentOwnerAddressFromPDRTokenId(uint256 _pdrTokenId) public view returns(address){
        return tokenIdToTokenOwner[_pdrTokenId];
    }
    
    // rwo token id -> owner
    function getRWONFTOwner(uint256 _rwoTokenId) public view returns(address){
        return holdersRWO[_rwoTokenId];
    }

    // rwo token id -> pdr token ids: getChildTokenIdsByParent
    function getPDRTokenIdsFromRWOTokenId(uint tokenId_RWO) public view returns(uint[] memory){
        return mapParent[tokenId_RWO];
    }

    function getPropertyData(uint _pdrTokenId, uint _time) public view returns (address _originalOwner, string memory _location, uint _tokensAsBond, address[] memory ownerRental, uint _parentId, address parentOwner){
        baseNFT memory property = entries[_pdrTokenId];
        address[] memory _ownerRental = ownerOfRental(_pdrTokenId, _time);
        return (
            property.originalOwner, 
            property.location, 
            property.amountPerNFT,
            _ownerRental, 
            getRWOTokenIdFromPDRTokenId(_pdrTokenId), getParentOwnerAddressFromPDRTokenId(_pdrTokenId) 
        );
    }

    function getBalancePDR(uint256 _tokenId, uint256 _start, uint256 _end, address _renter) public view returns (uint256){
        require(_start <= _end);
        uint _startIndex = _start.div(minRentTime);
        uint _endIndex = _end.div(minRentTime);
        uint rentalTokenCount = 0;

        for (uint i = _startIndex; i < _endIndex; i++) {
            //If rental is 0 for that time, return balance of owner
            if(rentals[_tokenId][i].length ==0){
                return balanceOf(tokenIdToTokenOwner[_tokenId], _tokenId);
            }
            for (uint j = 0; i < rentals[_tokenId][i].length; i++) {
                if (address(rentals[_tokenId][i][j] ) == address(_renter)) {
                    rentalTokenCount.add(amountRentalTokenId[_tokenId].sub(rentalAmount[block.timestamp][_tokenId]));
                }
            }
        }
        return rentalTokenCount;
    }

    function balanceOfRentalCurrentTime(uint _tokenId) public view returns(uint){
        return amountRentalTokenId[_tokenId].sub(rentalAmount[block.timestamp][_tokenId]);
    }

    function balanceOfRentalAtSpecTime(uint256 _tokenId, uint _time) public view returns (uint256){  
        return amountRentalTokenId[_tokenId].sub(rentalAmount[_time][_tokenId]);
    }

    // ownership functions: rename this function to override erc1155
    function ownerOfRental(uint _tokenId, uint _time) public view returns(address[] memory renter){
        uint timeIndex = _time.div(minRentTime);
        if(rentals[_tokenId][timeIndex].length == 0){
            address[] memory ownerNFT = new address[](1);
            //TODO: make it null address
            ownerNFT[0] = address(getParentOwnerAddressFromPDRTokenId(_tokenId));
            return ownerNFT;
        }
        return rentals[_tokenId][timeIndex];
    }

    // details of all child token ids from parent token id
    function getPDRDetailsByRWOTokenId(uint tokenId_RWO) public view returns(baseNFT[] memory){
        uint lenAd = mapParent[tokenId_RWO].length;
        baseNFT[] memory ads = new baseNFT[](lenAd);
        for(uint i=0; i< mapParent[tokenId_RWO].length; i++){
            ads[i] = entries[mapParent[tokenId_RWO][i]];
        }
        return ads;
    }

    function makePaymentforRWO(address  _from, address _to, uint _tokenId, uint _amount, bytes memory _data) public{
        _safeTransferFrom(_from, _to, _tokenId, _amount, _data);
    }

    // Transfer RWO NFTs
    function transferRWONFT(address from, address to, uint256 _tokenId, bytes calldata data) public{
        baseNFT memory property = entries[_tokenId];
        // console.log(type(property.typeOfNFT));
        require(property.typeOfNFT == TypeOfNFT.RWO);

        address _prevOwner = holdersRWO[_tokenId];
        // updating rwo nft owner
        holdersRWO[_tokenId] = to;

        // Optional: can emit property nft is transferred
        makePaymentforRWO(from, to, _tokenId, 1, data);
        
        for(uint i=0; i< mapParent[_tokenId].length; i++){
            delete childTokenOwner[_prevOwner][mapParent[_tokenId][i]];

            // update child token id owner
            tokenIdToTokenOwner[mapParent[_tokenId][i]] = holdersRWO[_tokenId];
            childTokenOwner[holdersRWO[_tokenId]][mapParent[_tokenId][i]] = _tokenId;
            
            makePaymentforRWO(from, to, mapParent[_tokenId][i], balanceOf(from, mapParent[_tokenId][i]), data);
            // Optional: can emit advertisment nft is transferred
        }
    }

    // rental utility functions
    function setRenterRights(uint _tokenId, address _renter, bool _canBurn, bool _canTransferToAll, bool _canTransferToPreapproved, bool _canCopyAcrossRights) public{
        require(balanceOf(msg.sender, _tokenId) > 0);
        renterRights[_tokenId][_renter] = RentalTokenRights(
            _canBurn, _canTransferToAll, _canTransferToPreapproved, _canCopyAcrossRights);
    }

    function updateRentalIntention(uint _tokenId, address _erc20Address) public{
        ERC20 token = ERC20(_erc20Address);
        baseNFT memory advertisementNFT = entries[_tokenId];

        //Check allowance function
        require(token.allowance(msg.sender, address(this)) > advertisementNFT.amountPerNFT);
        rentalIntention[_tokenId][msg.sender] = true;
    }

    function getTimeIndices(uint _start, uint _end) public view returns (uint startIndex, uint endIndex) {
        require(_start <= _end);
        uint _startIndex = _start.div(minRentTime);
        uint _endIndex = _end.div(minRentTime);
        return (_startIndex, _endIndex);
    }

    // @dev check availability
    function rentalAvailable(uint _tokenId, uint _timeIndex) public view returns (bool) {
        return rentalAmount[_timeIndex][_tokenId] <= amountRentalTokenId[_tokenId]; 
    }

    function copyAcrossRights(uint _tokenId, address _from, address _to) internal {
        RentalTokenRights memory rentalTokenRightsFrom = renterRights[_tokenId][_from];
        RentalTokenRights storage rentalTokenRightsTo = renterRights[_tokenId][_to];
        rentalTokenRightsTo.canBurn = rentalTokenRightsFrom.canBurn;
        rentalTokenRightsTo.canTransferToAll = rentalTokenRightsFrom.canTransferToAll;
        rentalTokenRightsTo.canTransferToPreapproved = rentalTokenRightsFrom.canTransferToPreapproved;
        rentalTokenRightsTo.canCopyAcrossRights = rentalTokenRightsFrom.canCopyAcrossRights;
    }

    // Main rental functions: mintRenting
    function rentPDR(uint _tokenId, uint _amount, uint _start, uint _end, address _renter, address _erc20Token) public{
        require(_amount<= amountRentalTokenId[_tokenId]);

        uint _startIndex;
        uint _endIndex;
        (_startIndex, _endIndex) = getTimeIndices(_start, _end);

        // baseNFT memory property = entries[_tokenId];
        // require(_start > property.initialAvailableDate);

        // check availability (for all time slots in range)
        // for (uint i = _startIndex; i <= _endIndex; i++) {
        //     require(rentalAvailable(_tokenId, i));
        // }

        // updating max end time - used when burning pdr nfts
        if(pdrTokenIdToEndTime[_tokenId] < _endIndex)
            pdrTokenIdToEndTime[_tokenId] = _endIndex;

        // check if there is intention to rent
        require(rentalIntention[_tokenId][_renter] == true);
        uint totalPayment = _amount;//.mul(property.amountPerNFT);
        
        balRental[_renter][_tokenId] =  balRental[_renter][_tokenId].add(totalPayment);

        // Platform Fee: to platformFeeAccumulatorAddress
        makePayment(_erc20Token, _renter, platformFeeAccumulatorAddress, (totalPayment.mul(10)).div(100));

        // Crypto payment: to existing rental
        makePayment(_erc20Token, _renter, tokenIdToTokenOwner[_tokenId], (totalPayment.mul(90)).div(100));

        // Add rental tokens
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            (rentals[_tokenId][i]).push(_renter);
            rentalAmount[i][_tokenId] = (rentalAmount[i][_tokenId]).add(_amount);
        }
        
        emit MintRental(_tokenId, _start, _end, _renter);
    }

    // @dev: Renter wants to transfer to another renter
    function transferRentalFrom(address _from, address _to, uint _tokenId, uint _start, uint _end, uint _amount, address _erc20Token) public {
        uint _startIndex;
        uint _endIndex;
        (_startIndex, _endIndex) = getTimeIndices(_start, _end);
        
        // check availability (for all time slots in range)
        // for (uint i = _startIndex; i <= _endIndex; i++) {
        //     require(rentalAvailable(_tokenId, i));
        // }

        // require(_amount<= amountRentalTokenId[_tokenId], "amount>bal left");
        
        // // bool isRenter = true;
        // bool isRentalTokenApproved = true;

        //TODO: check the rental approval and isrenter for giving permission for renter to further rent the nft
        // for (uint i = _startIndex; i < _endIndex; i++) {
        //     if (searchRenter(_tokenId, i, msg.sender)) {//not equal
        //         isRenter = false;
        //     }
        //     if (rentalTokenApprovals[_tokenId][i] != msg.sender) {
        //         isRentalTokenApproved = false;
        //     }
        // }
        // require(isRenter || isRentalTokenApproved, "2..");

        // RentalTokenRights memory rentalTokenRights = renterRights[_tokenId][_from];
        // require((rentalTokenRights.canBurn && _to == address(0x0)) ||
        //         (rentalTokenRights.canTransferToAll) ||
        //         (rentalTokenRights.canTransferToPreapproved && preapprovedRenters[_tokenId][_to] == true));

        // if (rentalTokenRights.canCopyAcrossRights) {
        //     copyAcrossRights(_tokenId, _from, _to);
        // }

        if (_to != address(0x0)) {
            // address ownerRWO = tokenIdToTokenOwner[_tokenId];
            
            require(rentalIntention[_tokenId][_to] == true);

            // charge bondTaken
            baseNFT memory property = entries[_tokenId];
            uint totalPayment = _amount.mul(property.amountPerNFT);

            balRental[_to][_tokenId] =  balRental[_to][_tokenId].add(totalPayment);

            // Platform Fee: to platformFeeAccumulatorAddress
            makePayment(_erc20Token, _to, platformFeeAccumulatorAddress, (totalPayment.mul(10)).div(100));

            //Royalities: to owner of RWO owner
            makePayment(_erc20Token, _to, tokenIdToTokenOwner[_tokenId], (totalPayment.mul(10)).div(100));

            // Crypto payment: to existing rental
            makePayment(_erc20Token, _to, _from, (totalPayment.mul(80)).div(100));
        }

        for (uint256 i = _startIndex; i < _endIndex; i++) {
            (rentals[_tokenId][i]).push(_to);
        }

        emit TransferRentalFrom(_from, _to, _tokenId, _start, _end);
    }

    function isPDRNFTAvailable(uint _tokenId, uint _start) public view returns(bool){
        baseNFT memory adNFT = entries[_tokenId];
        return (_start == adNFT.initialAvailableDate);
    }

    // Renew PDR NFTs
    function renewPDRRentTimePeriod(uint _tokenId, uint _amount, uint _start, uint _end, address _renter, address _erc20Token) public {
        
        //owner of RWO NFT
        address _ownerRWO = tokenIdToTokenOwner[_tokenId];
        require(msg.sender == _ownerRWO);
        baseNFT memory property = entries[_tokenId];
        require(_start > property.initialAvailableDate);
        require(property.typeOfNFT == TypeOfNFT.PDR);
        // require(_amount<= amountRentalTokenId[_tokenId], "amount>bal left");

        uint _startIndex;
        uint _endIndex;
        (_startIndex, _endIndex) = getTimeIndices(_start, _end);

        // check availability (for all time slots in range)
        for (uint i = _startIndex; i <= _endIndex; i++) {
            require(rentalAvailable(_tokenId, i));
        }
        
        uint totalPayment = _amount.mul(property.amountPerNFT);

        balRental[_renter][_tokenId] =  balRental[_renter][_tokenId].add(totalPayment);

        // Platform Fee: to platformFeeAccumulatorAddress
        makePayment(_erc20Token, _renter, platformFeeAccumulatorAddress, (totalPayment.mul(10)).div(100));

        // Crypto payment: to existing rental
        makePayment(_erc20Token, _renter, _ownerRWO, (totalPayment.mul(90)).div(100));

        // mint rental tokens
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            (rentals[_tokenId][i]).push(_renter);
            rentalAmount[i][_tokenId] = (rentalAmount[i][_tokenId]).add(_amount);
        }

        emit RenewRental(_tokenId, _start, _end);
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return tokenURIMapping[_tokenId];
    }
    
    // Distribute Revenue - PDR Rent NFT
    function distribute(uint256 _tokenId, uint256 _amountPerNFT, address _ERC20TokenAddress, address[] calldata accounts) public {
        require(balanceOf(msg.sender, _tokenId) > 0);
        require(_ERC20TokenAddress != address(0));        
        uint256 fee;

        for (uint256 i = 0; i < accounts.length; i++) {
            address holder = accounts[i];
            fee = _amountPerNFT.mul(balanceOf(holder, _tokenId));

            // Platform Fee: to platformFeeAccumulatorAddress
            makePayment(_ERC20TokenAddress, msg.sender, platformFeeAccumulatorAddress, ((platformFeePercentage).mul(fee)).div(100));

            // Crypto payment: to holder
            makePayment(_ERC20TokenAddress, msg.sender, holder, ((fee).mul(90)).div(100));
        }
    }

    // function distributeMatic(uint256 _tokenId, uint256 _amountPerNFT, address[] calldata accounts) public payable{
    //     require(balanceOf(msg.sender, _tokenId) > 0);
    //     require(msg.value >= 0.001 ether, "failed");
        
    //     uint256 fee;

    //     for (uint256 i = 0; i < accounts.length; i++) {
    //         address holder = accounts[i];
    //         fee = _amountPerNFT.mul(balanceOf(holder, _tokenId));

    //         // Platform Fee: to platformFeeAccumulatorAddress
    //         // makePayment(_ERC20TokenAddress, msg.sender, platformFeeAccumulatorAddress, ((platformFeePercentage).mul(fee)).div(100));
    //         (bool success, ) = platformFeeAccumulatorAddress.call{value: ((platformFeePercentage).mul(fee)).div(100)}("");
    //         require(success, "failed transfer");

    //         // Crypto payment: to holder
    //         (success, ) = holder.call{value: ((fee).mul(99)).div(100)}("");
    //         require(success, "failed transfer");
    //     }
    // }

    // function distributeMatic(address accounts) public payable{     
    //     uint256 fee;
    //     require(msg.value >= 0.001 ether, "failed");
    //         fee = 0.001 ether;
    //         // sending matic -> addr1
    //         (bool success, ) = accounts.call{value: fee}("");
    //         require(success, "failed transfer");
    //         // (success, ) = accounts.call{value: fee}("");
    //         // require(success, "failed transfer");
    // }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

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
    // constructor(string memory uri_) {
    //     _setURI(uri_);
    // }

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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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
     * Emits a {ApprovalForAll} event.
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}