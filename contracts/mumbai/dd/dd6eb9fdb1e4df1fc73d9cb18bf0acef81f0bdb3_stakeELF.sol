/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

// File: token/IERC721.sol

pragma solidity >=0.8.0 <0.9.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
// File: utils/IELFCore.sol

pragma solidity >=0.8.0 <0.9.0;


interface IELFCore is IERC721{

    function isHatched(uint256 _tokenId) external view returns (bool res);
    function gainELF(uint _tokenId) external view returns (uint label, uint dad, uint mom, uint gene, uint bornAt, uint[] memory children);
}
// File: token/IERC20.sol

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    /// MUST trigger when tokens are transferred, including zero value transfers.
    /// A token contract which creates new tokens SHOULD trigger a Transfer event with 
    ///  the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// Returns the total token supply.
    function totalSupply() external view returns (uint256);

    /// Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
    /// The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    /// The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
    /// This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. 
    /// The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// Allows _spender to withdraw from your account multiple times, up to the _value amount. 
    /// If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
// File: security/AccessControl.sol

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}
// File: security/Pausable.sol

pragma solidity >=0.8.0 <0.9.0;


contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}
// File: stakeELF.sol

pragma solidity >=0.8.0 <0.9.0;




contract stakeELF is Pausable {
    IELFCore immutable ELFCore;
    IERC20 immutable ROE;
    uint public totalEggs;

    struct EGG {
        uint id;
        uint t; //stake timestamp
        uint i; //corresponding index of prices when EGG is created/withdrawn
        uint price;
        uint bornAt;
        uint gene;
        uint rewardStartingPoint; // the time when this egg can earn reward
    }

    uint constant denominator = 60;//8760;// hours per year
    uint constant unit = 60; //3600; //seconds per hour;
    uint constant noRewardTime= 3 minutes;//1 days;
    uint constant maxStakingPeriod=60 minutes;//365 days;

    /// @dev extraRewardTable[i] means the extra reward of ith day.
    mapping(uint => uint) public extraRewardTable;

    /// @dev Operators who can set APR.
    address[] ops;
    mapping(address => bool) isOp;

    /// @dev Accumulated damage done to altars. Its value lies between [0,90].
    mapping(address => uint) public altar;

    /// @dev 9 attributes, price/APR.
    uint[2][9][] prices;

    /// @dev Mapping index of array prices to timestamp it was created.
    mapping(uint => uint) public tPrices;

    /// @dev Eggs staked by address.
    mapping(address => EGG[]) public eggs;

    /// @dev withdrawn[addr][i] means whether eggs[addr][i] has been withdrawn.
    mapping(address => mapping(uint => bool)) public withdrawn;

    /// @dev expired[addr][i] means whether eggs[addr][i] has expired.
    mapping(address => mapping(uint => bool)) public expired;

    /// @dev lastWithdrawTime[addr][i] is the timestamp of the last withdrawn of eggs[addr][i].
    ///  When lastWithdrawTime[addr][i]!=0, (lastWithdrawTime[addr][i]-rewardStartingPoint)/unit shuold be an integer.
    mapping(address => mapping(uint => uint)) public lastWithdrawTime;

    event ExtraRewardTableChanged(address indexed sender, uint t, uint day, uint value);

    /// @dev Should be fired whenever new term is added to array prices.
    event PriceChanged(address indexed sender, uint t, uint[2][9] p);

    /// @dev Fire whenever someone stake an egg.
    event Staking(address indexed staker, uint indexed id, uint t);

    /// @dev Fire whenever someone claim his/her reward.
    event Withdrawing(address indexed staker, uint amount, uint t, uint altarDamage);

    constructor(address ELF, address _ROE) {
        ELFCore = IELFCore(ELF);
        ROE = IERC20(_ROE);
    }

    modifier needPricesSet{
        require(tPrices[0]!=0,'price not set');
        _;
    }

    function getOps() external view returns (address[] memory res) {
        return ops;
    }

    function transferELF(address to, uint id) external onlySuperAdmin {
        ELFCore.transferFrom(address(this), to, id);
    }

    function transferROE(address to, uint amount) external onlySuperAdmin {
        ROE.transfer(to, amount);
    }

    function setOps(address op, bool tf) external onlySuperAdmin {
        if (isOp[op] != tf) {
            isOp[op] = tf;
            if (tf) {
                ops.push(op);
            } else {
                // remove element from ops
                uint i;
                uint l = ops.length;
                while (i < l) {
                    if (ops[i] == op) break;
                    i++;
                }
                ops[i] = ops[l - 1];
                ops.pop();
            }
        }
    }

    function setExtraRewardTable(uint day, uint value) external {
        require(isOp[msg.sender], NO_PERMISSION);
        extraRewardTable[day]=value;
        emit ExtraRewardTableChanged(msg.sender, block.timestamp, day, value);
    }

    function setPrices(uint[2][9] calldata p) external {
        require(isOp[msg.sender], NO_PERMISSION);
        uint t = block.timestamp;
        tPrices[prices.length] = t;
        prices.push(p);
        emit PriceChanged(msg.sender, t, p);
    }

    function getPrices(uint i) external view returns(uint[2][9] memory res) {
        return prices[i];
    }

    /// @dev The unit of res is %.
    function getYearlyReward() external view returns(uint res) {
        uint index=prices.length-1;
        for (uint i; i<9; i++) {
            res=res+prices[index][i][1];
        }
        res/=9;
        res+=1100;
    }

    function userStakeEggs(address addr) external view returns(uint res){
        return eggs[addr].length;
    }

    function stake(uint[] calldata ids) external needPricesSet{
        uint t = block.timestamp;
        uint pricesIndex=prices.length-1;
        totalEggs=ids.length+totalEggs;
        for (uint i=0;i<ids.length;i++){
            require(msg.sender == ELFCore.ownerOf(ids[i]),NO_PERMISSION);
            require(!ELFCore.isHatched(ids[i]), 'egg hatched');
            (, , , uint gene, uint bornAt, ) = ELFCore.gainELF(ids[i]);
            uint rewardStartingPoint;
            if (bornAt<t+noRewardTime) rewardStartingPoint=t+noRewardTime;
            else rewardStartingPoint=bornAt;
            EGG memory _EGG = EGG({
                id: ids[i],
                t: t,
                i: pricesIndex,
                price: prices[pricesIndex][gene - 1][0],
                bornAt: bornAt,
                gene: gene,
                rewardStartingPoint: rewardStartingPoint
            });

            eggs[msg.sender].push(_EGG);
            ELFCore.transferFrom(msg.sender, address(this), ids[i]);
            emit Staking(msg.sender, ids[i], t);
        }
        if (altar[msg.sender] <= 10*ids.length) altar[msg.sender] = 0;
        else altar[msg.sender] -= 10*ids.length;
    }

    function withdraw() external needPricesSet{
        uint amount;
        uint t = block.timestamp;
        EGG[] memory _eggs = eggs[msg.sender];

        for (uint i=0; i<_eggs.length; i++) { //iterate through all eggs.
            uint rewardStartingPoint=_eggs[i].rewardStartingPoint;
            uint totalTime;
            if (!withdrawn[msg.sender][i] && t>rewardStartingPoint){
                //staking reward + extra reward
                totalTime = t - rewardStartingPoint;//the total seconds caller can earn reward
                if (totalTime>=unit) {
                    withdrawn[msg.sender][i]=true;
                    if (totalTime>=maxStakingPeriod) {
                        expired[msg.sender][i]=true;
                        totalTime=maxStakingPeriod;
                    }
                    amount+=calculateExtraRewardPercentage(totalTime)*_eggs[i].price/100;
                }
            }
            else if (!expired[msg.sender][i]){
                //only staking reward
                if (t-rewardStartingPoint>=maxStakingPeriod) {
                    expired[msg.sender][i]=true;
                    totalTime=rewardStartingPoint+maxStakingPeriod-lastWithdrawTime[msg.sender][i];
                }
                else totalTime = t - lastWithdrawTime[msg.sender][i];
            }
            (uint eggAmount, uint eggIndex, uint tempLastWithdrawTime)=stakingReward(totalTime, _eggs[i], i, msg.sender);
            amount+=eggAmount;
            eggs[msg.sender][i].i=eggIndex;
            lastWithdrawTime[msg.sender][i]=tempLastWithdrawTime;
        }

        if (amount > 0) {
            uint altarTemp = altar[msg.sender];
            amount = amount * (100 - altarTemp) / 100;
            altarTemp = altarTemp + block.timestamp % 8 + 3;
            if (altarTemp > 90) altarTemp = 90;
            altar[msg.sender] = altarTemp;
            ROE.transfer(msg.sender, amount);
            emit Withdrawing(msg.sender, amount, t, 100-altarTemp);
        }
    }

    function getWithdrawValue(address addr) external view needPricesSet returns(uint amount, uint t){
        t = block.timestamp;
        EGG[] memory _eggs = eggs[addr];

        for (uint i=0; i<_eggs.length; i++) { //iterate through all eggs.
            uint rewardStartingPoint=_eggs[i].rewardStartingPoint;
            uint totalTime;
            if (!withdrawn[addr][i] && t>rewardStartingPoint){
                //staking reward + extra reward
                totalTime = t - rewardStartingPoint;//the total seconds caller can earn reward
                if (totalTime>=unit) {
                    if (totalTime>=maxStakingPeriod) totalTime=maxStakingPeriod;
                    amount+=calculateExtraRewardPercentage(totalTime)*_eggs[i].price/100;
                }
            }
            else if (!expired[addr][i]){
                //only staking reward
                if (t-rewardStartingPoint>=maxStakingPeriod) totalTime=rewardStartingPoint+maxStakingPeriod-lastWithdrawTime[addr][i];
                else totalTime = t - lastWithdrawTime[addr][i];
            }
            (uint eggAmount,,)=stakingReward(totalTime, _eggs[i], i, addr);
            amount+=eggAmount;
        }

        amount = amount * (100 - altar[addr]) / 100;
    }

    /// @dev Unit of returnd value percentage is %.
    function getAverageWithdrawPercentage(address addr) external view needPricesSet returns(uint percentage, uint t){
        t = block.timestamp;
        EGG[] memory _eggs = eggs[addr];
        uint count;

        for (uint i=0; i<_eggs.length; i++) { //iterate through all eggs.
            uint rewardStartingPoint=_eggs[i].rewardStartingPoint;
            uint totalTime;
            if (!withdrawn[addr][i] && t>rewardStartingPoint){
                //staking reward + extra reward
                totalTime = t - rewardStartingPoint;//the total seconds caller can earn reward
                if (totalTime>=unit) {
                    if (totalTime>=maxStakingPeriod) totalTime=maxStakingPeriod;
                    percentage+=calculateExtraRewardPercentage(totalTime);
                    count++;
                }
            }
            else if (!expired[addr][i]){
                //only staking reward
                if (t-rewardStartingPoint>=maxStakingPeriod) totalTime=rewardStartingPoint+maxStakingPeriod-lastWithdrawTime[addr][i];
                else totalTime = t - lastWithdrawTime[addr][i];
                count++;
            }
            (uint eggAmount,,)=stakingReward(totalTime, _eggs[i], i, addr);
            percentage+=eggAmount*100/_eggs[i].price;
        }

        percentage=percentage*(100-altar[addr])/100/count;
    }

    function getWithdrawDiff(address addr) external view needPricesSet returns(uint diff, uint t){
        t = block.timestamp;
        EGG[] memory _eggs = eggs[addr];
        uint amount;
        uint maxExtraRewardPercentage=calculateExtraRewardPercentage(365 days);

        for (uint i=0; i<_eggs.length; i++) { //iterate through all eggs.
            uint rewardStartingPoint=_eggs[i].rewardStartingPoint;
            uint totalTime;
            if (!withdrawn[addr][i] && t>rewardStartingPoint){
                //staking reward + extra reward
                totalTime = t - rewardStartingPoint;//the total seconds caller can earn reward
                if (totalTime>=unit) {
                    if (totalTime>=maxStakingPeriod) totalTime=maxStakingPeriod;
                    uint extraReward=calculateExtraRewardPercentage(totalTime)*_eggs[i].price/100;
                    amount+=extraReward;
                    diff+=maxExtraRewardPercentage*_eggs[i].price/100-extraReward;
                }
            }
            else if (!expired[addr][i]){
                //only staking reward
                if (t-rewardStartingPoint>=maxStakingPeriod) totalTime=rewardStartingPoint+maxStakingPeriod-lastWithdrawTime[addr][i];
                else totalTime = t - lastWithdrawTime[addr][i];
            }
            (uint eggAmount,,)=stakingReward(totalTime, _eggs[i], i, addr);
            amount+=eggAmount;
        }

        diff=diff+amount*altar[addr]/100;
    }

    /// @dev Unit of returnd value res is %.
    function calculateExtraRewardPercentage(uint totalTime) internal view returns(uint res) {
        uint l=totalTime/1 days;
        for (uint i=1; i<l+1; i++){
            res+=extraRewardTable[i];
        }
    }

    function stakingReward(uint totalTime, EGG memory egg, uint i, address addr) internal view returns(uint amount, uint indexOfPrices, uint tempLastWithdrawTime) {
        uint accumulatedTime; // accumulated seconds whose reward have been calculated
        indexOfPrices = egg.i;
        uint rewardStartingPoint=egg.rewardStartingPoint;
        tempLastWithdrawTime=lastWithdrawTime[addr][i];
        while (totalTime-accumulatedTime>=unit){ //iterate through terms of prices
            uint unitDiff;
            if (tPrices[indexOfPrices+1]==0){ //next term of prices does not exist
                unitDiff=(totalTime-accumulatedTime)/unit;
                accumulatedTime=totalTime;
                amount=amount+egg.price*prices[indexOfPrices][egg.gene-1][1]/100*unitDiff/denominator;
            }
            else{ //next term of prices exists
                uint secondDiff;
                if (tempLastWithdrawTime==0) secondDiff=tPrices[indexOfPrices+1]-rewardStartingPoint;
                else secondDiff=tPrices[indexOfPrices+1]-tempLastWithdrawTime;
                uint remainder=secondDiff%unit;
                secondDiff=secondDiff-remainder;

                if (accumulatedTime+secondDiff>totalTime) {
                    unitDiff=(totalTime-accumulatedTime)/unit;
                    accumulatedTime=totalTime;
                    amount=amount+egg.price*prices[indexOfPrices][egg.gene-1][1]/100*unitDiff/denominator;
                }
                else {
                    unitDiff=secondDiff/unit;
                    if (remainder!=0 && accumulatedTime+secondDiff+unit<=totalTime) unitDiff++;
                    accumulatedTime+=unitDiff*unit;
                    amount=amount+egg.price*prices[indexOfPrices][egg.gene-1][1]/100*unitDiff/denominator;
                    indexOfPrices++;
                }
            }
            if (tempLastWithdrawTime==0) tempLastWithdrawTime=rewardStartingPoint+unitDiff*unit;
            else tempLastWithdrawTime+=unitDiff*unit;
        }
    }
}