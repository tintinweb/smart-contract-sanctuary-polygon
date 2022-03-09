// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

/*$$$$$$$ /$$                            /$$$$$$  /$$   /$$              
|__  $$__/| $$                           /$$__  $$|__/  | $$              
   | $$   | $$$$$$$  /$$   /$$  /$$$$$$ | $$  \__/ /$$ /$$$$$$   /$$   /$$
   | $$   | $$__  $$| $$  | $$ /$$__  $$| $$      | $$|_  $$_/  | $$  | $$
   | $$   | $$  \ $$| $$  | $$| $$  \ $$| $$      | $$  | $$    | $$  | $$
   | $$   | $$  | $$| $$  | $$| $$  | $$| $$    $$| $$  | $$ /$$| $$  | $$
   | $$   | $$  | $$|  $$$$$$/|  $$$$$$$|  $$$$$$/| $$  |  $$$$/|  $$$$$$$
   |__/   |__/  |__/ \______/  \____  $$ \______/ |__/   \___/   \____  $$
                               /$$  \ $$                         /$$  | $$
                              |  $$$$$$/                        |  $$$$$$/
                               \______/                          \______*/

import "./ERC721.sol";
import "./Ownable.sol";

// Interface for NFT contract
interface IThugCityNFT {
    function ownerOf(uint256 id) external view returns (address);

    function isCop(uint16 id) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;
}

// Interface for $BILLS token contract
interface IBills {
    function mint(address account, uint256 amount) external;
}

contract City is Ownable, IERC721Receiver {
    bool private _paused = false;

    mapping(uint256 => address) private _randomSource;
    uint16 private _randomIndex = 0;
    uint256 private _randomCalls = 0;

    //Store stake values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event ThugClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event CopClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    //Initialize citizen
    IThugCityNFT public citizen;
    //Initialize bills
    IBills public bills;

    //Map cop to stake
    mapping(uint256 => uint256) public copCollection;
    mapping(address => Stake[]) public copStake;
    //Total cop staked
    uint256 public totalCopsStaked = 0;
    //Rewards when no cops staked
    uint256 public unclaimedRewards = 0;

    //Map thug to stake
    mapping(uint256 => uint256) public thugCollection;
    mapping(address => Stake[]) public thugStake;
    //Total thug staked
    uint256 public totalThugsStaked;

    //Daily rates and maximums
    uint256 public constant DAILY_BILLS_RATE = 10000 ether;
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    uint256 public constant COP_TAX_PERCENTAGE = 20;
    uint256 public constant MAXIMUM_GLOBAL_BILLS = 2400000000 ether;

    //Total bills earned
    uint256 totalBillsEarned;
    //Time since BILLS claimed
    uint256 public lastClaimTimeStamp;
    //Thug reward
    uint256 public copReward = 0;
    //Current Cop holders
    address[] public copHolders;

    //Emergency rescue to allow unstaking without any checks but without $BILLS
    bool public rescueEnabled = false;

    constructor() {
        //Random source addresses
        _randomSource[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _randomSource[1] = 0x3cD751E6b0078Be393132286c442345e5DC49699;
        _randomSource[2] = 0xb5d85CBf7cB3EE0D56b3bB207D5Fc4B82f43F511;
        _randomSource[3] = 0xC098B2a3Aa256D2140208C3de6543aAEf5cd3A94;
        _randomSource[4] = 0x28C6c06298d514Db089934071355E5743bf21d60;
        _randomSource[5] = 0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2;
        _randomSource[6] = 0x267be1C1D684F78cb4F6a176C4911b741E4Ffdc0;
    }

    //Pausable clauses
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    //Setting citizens and bills links
    function setCitizen(address _citizen) external onlyOwner {
        citizen = IThugCityNFT(_citizen);
    }

    function setBills(address _bills) external onlyOwner {
        bills = IBills(_bills);
    }

    function getAccountThugs(address user)
        external
        view
        returns (Stake[] memory)
    {
        return thugStake[user];
    }

    function getAccountCops(address user)
        external
        view
        returns (Stake[] memory)
    {
        return copStake[user];
    }

    //STAKING: Adds cops and/or thugs to thugcity
    function addManyToCity(address account, uint16[] calldata tokenIds) public {
        require(
            account == msg.sender || msg.sender == address(citizen),
            "Insufficient permissions."
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (msg.sender != address(citizen)) {
                require(
                    citizen.ownerOf(tokenIds[i]) == msg.sender,
                    "This NFT doesn't belong to you!"
                ); // checking with NFT contract for ownership
                citizen.transferFrom(msg.sender, address(this), tokenIds[i]);
            }

            if (tokenIds[i] == 0) {
                continue; //may be gaps in the array for stolen tokens
            }

            if (citizen.isCop(tokenIds[i])) {
                _addCopToCity(account, tokenIds[i]);
            } else {
                _addThugToCity(account, tokenIds[i]);
            }
        }
    }

    //STAKING: Adds single thug to thugcity
    function _addThugToCity(address account, uint16 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        totalThugsStaked += 1;

        thugCollection[tokenId] = thugStake[account].length;
        thugStake[account].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            })
        );
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    //STAKING: Adds single cop to thugcity
    function _addCopToCity(address account, uint16 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        totalCopsStaked += 1;

        copCollection[tokenId] = copStake[account].length;
        copStake[account].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(copReward)
            })
        );
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    //CLAIMING/UNSTAKING: Claim bills earnings from cops and/or thugs
    function claimManyFromCity(uint16[] calldata tokenIds, bool unstake)
        external
        whenNotPaused
        _updateEarnings
    {
        uint256 owed = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (citizen.isCop(tokenIds[i])) {
                owed += _claimFromCop(tokenIds[i], unstake);
            } else {
                owed += _claimFromThug(tokenIds[i], unstake);
            }
        }
        if (owed == 0) return;
        bills.mint(msg.sender, owed);
    }

    //CLAIMING/UNSTAKING: Claim bills earnings from single thug
    function _claimFromThug(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = thugStake[msg.sender][thugCollection[tokenId]];
        require(
            stake.owner == msg.sender,
            "This NFT does not belong to you..."
        );
        //require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "You've gotta wait 2 days to exit the hood!");

        if (totalBillsEarned < MAXIMUM_GLOBAL_BILLS) {
            owed =
                ((block.timestamp - stake.value) * DAILY_BILLS_RATE) /
                1 days;
        } else if (stake.value > lastClaimTimeStamp) {
            owed = 0; //$BILLS production stopped already
        } else {
            owed =
                ((lastClaimTimeStamp - stake.value) * DAILY_BILLS_RATE) /
                1 days; //stop earning additional $BILLS if it's all been earned
        }

        //If unstaking thug
        if (unstake) {
            if (getRandomNumber(tokenId, 100) <= 50) {
                _payCopTax(owed);
                owed = 0;
            }

            updateRandomIndex();

            //Move last thug to first position
            Stake memory lastStake = thugStake[msg.sender][
                thugStake[msg.sender].length - 1
            ];
            thugStake[msg.sender][thugCollection[tokenId]] = lastStake;
            thugCollection[lastStake.tokenId] = thugCollection[tokenId];
            thugStake[msg.sender].pop();

            //Removing staked thug and transferring to owner
            totalThugsStaked -= 1;
            delete thugCollection[tokenId];
            citizen.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            _payCopTax((owed * COP_TAX_PERCENTAGE) / 100); //Tax sent to cops
            owed = (owed * (100 - COP_TAX_PERCENTAGE)) / 100; //Tax remainder given to thug

            thugStake[msg.sender][thugCollection[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); //reset stake
        }

        emit ThugClaimed(tokenId, owed, unstake);
    }

    //CLAIMING/UNSTAKING: Claim bills earnings from single cop
    function _claimFromCop(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        require(
            citizen.ownerOf(tokenId) == address(this),
            "This cop isn't in the city!"
        );

        Stake memory stake = copStake[msg.sender][copCollection[tokenId]];

        require(stake.owner == msg.sender, "This NFT doesn't belong to you...");
        owed = (copReward - stake.value);

        if (unstake) {
            //Move last cop to first position
            Stake memory lastStake = copStake[msg.sender][
                copStake[msg.sender].length - 1
            ];
            copStake[msg.sender][copCollection[tokenId]] = lastStake;
            copCollection[lastStake.tokenId] = copCollection[tokenId];
            copStake[msg.sender].pop();

            //Removing staked cop and transferring to owner
            totalCopsStaked -= 1;
            delete copCollection[tokenId];
            citizen.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            copStake[msg.sender][copCollection[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: uint80(copReward)
            }); //Reset stake
        }
        emit CopClaimed(tokenId, owed, unstake);
    }

    //Emergency unstake tokens
    function rescue(uint16[] calldata tokenIds) external {
        require(rescueEnabled, "RESCUE DISABLED");
        uint16 tokenId;
        Stake memory stake;

        for (uint16 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (citizen.isCop(tokenId)) {
                stake = copStake[msg.sender][copCollection[tokenId]];

                require(
                    stake.owner == msg.sender,
                    "This NFT doesn't belong to you..."
                );

                Stake memory lastStake = copStake[msg.sender][
                    copStake[msg.sender].length - 1
                ];
                copStake[msg.sender][copCollection[tokenId]] = lastStake;
                copCollection[lastStake.tokenId] = copCollection[tokenId];
                copStake[msg.sender].pop();

                totalCopsStaked -= 1;
                delete copCollection[tokenId];
                citizen.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    ""
                );

                emit CopClaimed(tokenId, 0, true);
            } else {
                stake = thugStake[msg.sender][thugCollection[tokenId]];

                require(
                    stake.owner == msg.sender,
                    "This NFT doesn't belong to you..."
                );

                Stake memory lastStake = thugStake[msg.sender][
                    thugStake[msg.sender].length - 1
                ];
                thugStake[msg.sender][thugCollection[tokenId]] = lastStake;
                thugCollection[lastStake.tokenId] = thugCollection[tokenId];
                thugStake[msg.sender].pop();

                totalThugsStaked -= 1;
                delete thugCollection[tokenId];
                citizen.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    ""
                );

                emit ThugClaimed(tokenId, 0, true);
            }
        }
    }

    //ACCOUNTING: Thug tax to cops
    function _payCopTax(uint256 _amount) internal {
        if (totalCopsStaked == 0) {
            unclaimedRewards += _amount;
            return;
        }

        copReward += (_amount + unclaimedRewards) / totalCopsStaked;
        unclaimedRewards = 0;
    }

    //ACCOUNTING: bills earnings, stops at 2.4 billion
    modifier _updateEarnings() {
        if (totalBillsEarned < MAXIMUM_GLOBAL_BILLS) {
            totalBillsEarned +=
                ((block.timestamp - lastClaimTimeStamp) *
                    totalThugsStaked *
                    DAILY_BILLS_RATE) /
                1 days;
            lastClaimTimeStamp = block.timestamp;
        }
        _;
    }

    //OWNER: Enabling rescue command
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    //OWNER: Enable pausing of minting
    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }

    //MISC: Random cop owner
    function randomCopOwner() external returns (address) {
        if (totalCopsStaked == 0) return address(0x0);

        uint256 holderIndex = getRandomNumber(
            totalCopsStaked,
            copHolders.length
        );
        updateRandomIndex();

        return copHolders[holderIndex];
    }

    //MISC: Update random index
    function updateRandomIndex() internal {
        _randomIndex += 1;
        _randomCalls += 1;
        if (_randomIndex > 6) _randomIndex = 0;
    }

    //MISC: Get random number
    function getRandomNumber(uint256 _seed, uint256 _limit)
        internal
        view
        returns (uint16)
    {
        uint256 extra = 0;
        for (uint16 i = 0; i < 7; i++) {
            extra += _randomSource[_randomIndex].balance;
        }

        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    extra,
                    _randomCalls,
                    _randomIndex
                )
            )
        );

        return uint16(random % _limit);
    }

    //MISC: Change source of random numbers
    function changeRandomSource(uint256 _id, address _address)
        external
        onlyOwner
    {
        _randomSource[_id] = _address;
    }

    //MISC: Shuffle seeds of random numbers
    function shuffleSeeds(uint256 _seed, uint256 _max) external onlyOwner {
        uint256 shuffleCount = getRandomNumber(_seed, _max);
        _randomIndex = uint16(shuffleCount);
        for (uint256 i = 0; i < shuffleCount; i++) {
            updateRandomIndex();
        }
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(
            from == address(0x0),
            "Cannot send tokens to ThugCity directly"
        );
        return IERC721Receiver.onERC721Received.selector;
    }
}