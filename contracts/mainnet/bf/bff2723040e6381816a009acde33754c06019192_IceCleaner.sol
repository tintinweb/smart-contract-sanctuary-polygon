/**
 *Submitted for verification at polygonscan.com on 2022-05-24
*/

// File: contracts/common-contracts/CleanEvents.sol



pragma solidity ^0.8.13;

contract CleanEvents {

    event Cleaning(
        uint256 indexed tokenId,
        address indexed tokenAddress,
        address indexed playerAddress,
        uint256 pointsAmount
    );

    event Purchased(
        uint256 indexed tokenId,
        address indexed tokenAddress,
        address indexed playerAddress,
        uint256 pointsAmount
    );
}

// File: contracts/common-contracts/TransferHelper.sol



pragma solidity ^0.8.13;

contract TransferHelper {

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                "transfer(address,uint256)" // 0xa9059cbb
            )
        )
    );

    bytes4 private constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                "transferFrom(address,address,uint256)" // 0x23b872dd
            )
        )
    );

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER, // 0xa9059cbb
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

// File: contracts/common-contracts/AccessController.sol



pragma solidity ^0.8.13;

contract AccessController {

    address public ceoAddress;
    mapping (address => bool) public isWorker;

    event CEOSet(
        address newCEO
    );

    event WorkerAdded(
        address newWorker
    );

    event WorkerRemoved(
        address existingWorker
    );

    constructor() {

        address creator = msg.sender;
        ceoAddress = creator;
        isWorker[creator] = true;

        emit CEOSet(
            creator
        );

        emit WorkerAdded(
            creator
        );
    }

    modifier onlyCEO() {
        require(
            msg.sender == ceoAddress,
            "AccessControl: CEO_DENIED"
        );
        _;
    }

    modifier onlyWorker() {
        require(
            isWorker[msg.sender] == true,
            "AccessControl: WORKER_DENIED"
        );
        _;
    }

    modifier nonZeroAddress(
        address checkingAddress
    ) {
        require(
            checkingAddress != address(0x0),
            "AccessControl: INVALID_ADDRESS"
        );
        _;
    }

    function setCEO(
        address _newCEO
    )
        external
        nonZeroAddress(_newCEO)
        onlyCEO
    {
        ceoAddress = _newCEO;

        emit CEOSet(
            ceoAddress
        );
    }

    function addWorker(
        address _newWorker
    )
        external
        onlyCEO
    {
        _addWorker(
            _newWorker
        );
    }

    function addWorkerBulk(
        address[] calldata _newWorkers
    )
        external
        onlyCEO
    {
        for (uint8 index = 0; index < _newWorkers.length; index++) {
            _addWorker(_newWorkers[index]);
        }
    }

    function _addWorker(
        address _newWorker
    )
        internal
        nonZeroAddress(_newWorker)
    {
        require(
            isWorker[_newWorker] == false,
            'AccessControl: worker already exist'
        );

        isWorker[_newWorker] = true;

        emit WorkerAdded(
            _newWorker
        );
    }

    function removeWorker(
        address _existingWorker
    )
        external
        onlyCEO
    {
        _removeWorker(
            _existingWorker
        );
    }

    function removeWorkerBulk(
        address[] calldata _workerArray
    )
        external
        onlyCEO
    {
        for (uint8 index = 0; index < _workerArray.length; index++) {
            _removeWorker(_workerArray[index]);
        }
    }

    function _removeWorker(
        address _existingWorker
    )
        internal
        nonZeroAddress(_existingWorker)
    {
        require(
            isWorker[_existingWorker] == true,
            "AccessControl: worker not detected"
        );

        isWorker[_existingWorker] = false;

        emit WorkerRemoved(
            _existingWorker
        );
    }
}

// File: contracts/IceCleaner.sol



pragma solidity ^0.8.13;




interface RegistrantContract {

    function getHash(
        address _tokenAddress,
        uint256 _tokenId
    )
        external
        pure
        returns (bytes32);
}

contract IceCleaner is AccessController, TransferHelper, CleanEvents {

    address public immutable tokenAddressDG;
    address public immutable tokenAddressICE;

    RegistrantContract public immutable registrantContract;

    uint256 public costPerPointDG;
    uint256 public costPerPointICE;

    address public depositAddressDG;
    address public depositAddressICE;

    mapping(address => uint256) public totalSpent;
    mapping(address => mapping(bytes32 => uint256)) public pointLevel;
    mapping(address => mapping(bytes32 => uint256)) public spentPerNFT;

    mapping(uint256 => uint256) public pointsBulksDG;
    mapping(uint256 => uint256) public pointsBulksICE;

    constructor(
        address _tokenAddressDG,
        address _tokenAddressICE,
        address _registrantContract
    ) {
        tokenAddressDG = _tokenAddressDG;
        tokenAddressICE = _tokenAddressICE;

        registrantContract = RegistrantContract(
            _registrantContract
        );
    }

    function buyAndSpendBulk(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _bulkPriceDG,
        uint256 _bulkPriceICE
    )
        external
        onlyWorker
    {
        uint256 totalPointsForDG = pointsBulksDG[_bulkPriceDG];
        uint256 totalPointsForICE = pointsBulksICE[_bulkPriceICE];

        uint256 totalPoints = totalPointsForDG + totalPointsForICE;

        require(
            totalPoints > 0,
            "IceCleaner: NO_POINTS"
        );

        _buyAndSpend(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            totalPoints,
            _bulkPriceDG,
            _bulkPriceICE
        );
    }

    function buyAndSpend(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount
    )
        external
        onlyWorker
    {
        uint256 totalPriceDG = costPerPointDG
            * _pointsAmount;

        uint256 totalPriceICE = costPerPointICE
            * _pointsAmount;

        _buyAndSpend(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount,
            totalPriceDG,
            totalPriceICE
        );
    }

    function _buyAndSpend(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount,
        uint256 _totalPriceDG,
        uint256 _totalPriceICE
    )
        internal
    {
        bytes32 tokenHash = registrantContract.getHash(
            _tokenAddress,
            _tokenId
        );

        totalSpent[_playerAddress] =
        totalSpent[_playerAddress] + _pointsAmount;

        spentPerNFT[_playerAddress][tokenHash] =
        spentPerNFT[_playerAddress][tokenHash] + _pointsAmount;

        _takePayment(
            _totalPriceDG,
            _totalPriceICE,
            _playerAddress
        );

        emit Cleaning(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount
        );
    }

    function buyPoints(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount
    )
        external
        onlyWorker
    {
        uint256 totalPriceDG = costPerPointDG
            * _pointsAmount;

        uint256 totalPriceICE = costPerPointICE
            * _pointsAmount;

        _buyPoints(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount,
            totalPriceDG,
            totalPriceICE
        );
    }

    function buyPointsBulk(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _bulkPriceDG,
        uint256 _bulkPriceICE
    )
        external
        onlyWorker
    {
        uint256 totalPointsForDG = pointsBulksDG[_bulkPriceDG];
        uint256 totalPointsForICE = pointsBulksICE[_bulkPriceICE];

        uint256 totalPoints = totalPointsForDG + totalPointsForICE;

        require(
            totalPoints > 0,
            "IceCleaner: NO_POINTS"
        );

        _buyPoints(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            totalPoints,
            _bulkPriceDG,
            _bulkPriceICE
        );
    }

    function _buyPoints(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount,
        uint256 _totalPriceDG,
        uint256 _totalPriceICE
    )
        internal
    {
        bytes32 tokenHash = registrantContract.getHash(
            _tokenAddress,
            _tokenId
        );

        pointLevel[_playerAddress][tokenHash] =
        pointLevel[_playerAddress][tokenHash] + _pointsAmount;

        _takePayment(
            _totalPriceDG,
            _totalPriceICE,
            _playerAddress
        );

        emit Purchased(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount
        );
    }

    function spendPoints(
        uint256 _tokenId,
        address _tokenAddress,
        address _playerAddress,
        uint256 _pointsAmount
    )
        external
        onlyWorker
    {
        bytes32 tokenHash = registrantContract.getHash(
            _tokenAddress,
            _tokenId
        );

        totalSpent[_playerAddress] =
        totalSpent[_playerAddress] + _pointsAmount;

        spentPerNFT[_playerAddress][tokenHash] =
        spentPerNFT[_playerAddress][tokenHash] + _pointsAmount;

        pointLevel[_playerAddress][tokenHash] =
        pointLevel[_playerAddress][tokenHash] - _pointsAmount;

        emit Cleaning(
            _tokenId,
            _tokenAddress,
            _playerAddress,
            _pointsAmount
        );
    }

    function _takePayment(
        uint256 _dgAmount,
        uint256 _iceAmount,
        address _playerAddress
    )
        internal
    {
        if (_dgAmount > 0) {
            safeTransferFrom(
                tokenAddressDG,
                _playerAddress,
                depositAddressDG,
                _dgAmount
            );
        }

        if (_iceAmount > 0) {
            safeTransferFrom(
                tokenAddressICE,
                _playerAddress,
                depositAddressICE,
                _iceAmount
            );
        }
    }

    function setCostPerPointDG(
        uint256 _costPerPointDG
    )
        external
        onlyCEO
    {
        costPerPointDG = _costPerPointDG;
    }

    function setCostPerPointICE(
        uint256 _costPerPointICE
    )
        external
        onlyCEO
    {
        costPerPointICE = _costPerPointICE;
    }

    function setDepositAddressDG(
        address _depositAddressDG
    )
        external
        onlyCEO
    {
        depositAddressDG = _depositAddressDG;
    }

    function setDepositAddressICE(
        address _depositAddressICE
    )
        external
        onlyCEO
    {
        depositAddressICE = _depositAddressICE;
    }

    function setPointsBulkDG(
        uint256 _bulkPrice,
        uint256 _bulkPoints
    )
        external
        onlyCEO
    {
        pointsBulksDG[_bulkPrice] = _bulkPoints;
    }

    function setPointsBulkICE(
        uint256 _bulkPrice,
        uint256 _bulkPoints
    )
        external
        onlyCEO
    {
        pointsBulksICE[_bulkPrice] = _bulkPoints;
    }
}