//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Important Imports

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// Error Handling

error NFTVrf_AllreadyInitialized();
error NFTVrf_NeedMoreFunds();
error NFTVrf_RangeOurOfBounds();
error NFTVrf_TransferFailed();

// Contract

contract NFTVrf is ERC721URIStorage, VRFConsumerBaseV2, Ownable {
    struct Traits {
        uint256 speed;
        uint256 energy;
        uint256 agility;
        uint256 intellect;
        uint256 attackPower;
        uint256 defense;
    }

    mapping(address => Traits) IdToTraits;

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_suscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // NFT Variables
    uint256 private immutable i_mintFee;
    uint256 private tokenCounter;
    uint256 internal constant MAXIMUM_CHANCE_VALUE = 100;
    string[] internal tokenURIs;
    bool private initialized;

    // Helpers for Chainlink VRF
    mapping(uint256 => address) public requestIdToSender;

    // Events
    event NftRequested(uint256 indexed requestId, address requester);

    // Constructor with all the paremeter needed for Chainlink VRF and UriStorage NFTs
    constructor(
        address _vrfCoordinatorV2,
        uint64 _suscriptionId,
        bytes32 _gasLane,
        uint256 _mintFee,
        uint32 _callbackGasLimit,
        string[6] memory _tokenURIs
    )
        VRFConsumerBaseV2(_vrfCoordinatorV2)
        ERC721("Random IPFS NFT Moralis", "RMN")
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_gasLane = _gasLane;
        i_suscriptionId = _suscriptionId;
        i_mintFee = _mintFee;
        i_callbackGasLimit = _callbackGasLimit;
        // _initializeContract(tokenURIs);
        tokenCounter = 0;
    }

    // Request NFT based on the requestID
    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert NFTVrf_NeedMoreFunds();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_suscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    // Fulfill Chainlink Randomness Request

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address nftOwner = requestIdToSender[requestId];
        uint256 newItemId = tokenCounter;
        tokenCounter += 1;
        uint256 moddedRng = randomWords[0] % MAXIMUM_CHANCE_VALUE;
        //  IdToTraits[msg.sender] = getBreedFromModdedRng(moddedRng);
        _safeMint(nftOwner, newItemId);
    }

    // Get the Change to get a specific Breed
    function getChanceArray() public pure returns (uint256[6] memory) {
        return [5, 15, 35, 50, 70, MAXIMUM_CHANCE_VALUE];
    }
}
