// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ParkeyNFT
 * @dev tokenisation de places de parking
 */
contract ParkeyNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter = 0;

    // place de parking
    struct ParkingSpot {
        string parkingAddress;
        string parkingType; 
        string size; 
        uint256 price;
        bool isAvailable;
        bool available247;
        address currentOwner;
        uint256 createdAt;
    }

    // Mapping des tokens vers les places de parking
    mapping(uint256 => ParkingSpot) public parkingSpots;
    
    // Mapping des propriétaires vers leurs tokens
    mapping(address => uint256[]) public ownerTokens;
    
    // Frais de plateforme (2%)
    uint256 public platformFee = 2;
    
    // Adresse pour collecter les frais
    address public feeCollector;

    // Events
    event ParkingSpotCreated(
        uint256 indexed tokenId,
        address indexed owner,
        string parkingAddress,
        uint256 price
    );
    
    event ParkingSpotSold(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 price
    );
    
    event ParkingSpotListed(
        uint256 indexed tokenId,
        uint256 price,
        bool isAvailable
    );

    constructor() ERC721("Parkey Parking NFT", "PARK") ERC721URIStorage() Ownable(msg.sender) {
        feeCollector = msg.sender;
    }

    /**
     * @dev Crée un nouveau token de place de parking
     */
    function createParkingSpot(
        string memory _parkingAddress,
        string memory _parkingType,
        string memory _size,
        uint256 _price,
        bool _available247,
        string memory _tokenURI
    ) public returns (uint256) {
        require(_price > 0, "Le prix doit etre superieur a 0");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        
        parkingSpots[tokenId] = ParkingSpot({
            parkingAddress: _parkingAddress,
            parkingType: _parkingType,
            size: _size,
            price: _price,
            isAvailable: true,
            available247: _available247,
            currentOwner: msg.sender,
            createdAt: block.timestamp
        });
        
        ownerTokens[msg.sender].push(tokenId);
        
        emit ParkingSpotCreated(tokenId, msg.sender, _parkingAddress, _price);
        
        return tokenId;
    }


    /**
     * @dev Achète une place de parking
     */
    function buyParkingSpot(uint256 _tokenId) public payable {
        require(_exists(_tokenId), "Ce token n'existe pas");
        ParkingSpot storage spot = parkingSpots[_tokenId];
        require(spot.isAvailable, "Cette place n'est pas disponible");
        require(msg.value >= spot.price, "Prix insuffisant");
        require(ownerOf(_tokenId) != msg.sender, "Vous possedez deja ce token");
        
        address seller = ownerOf(_tokenId);
        
        // Calcul des frais
        uint256 fee = (msg.value * platformFee) / 100;
        uint256 sellerAmount = msg.value - fee;
        
        // Transfert des fonds
        payable(feeCollector).transfer(fee);
        payable(seller).transfer(sellerAmount);
        
        // Transfert du NFT
        _transfer(seller, msg.sender, _tokenId);
        
        // Mise à jour des données
        spot.currentOwner = msg.sender;
        spot.isAvailable = false;
        
        // Mise à jour des tokens du propriétaire
        _removeTokenFromOwner(seller, _tokenId);
        ownerTokens[msg.sender].push(_tokenId);
        
        emit ParkingSpotSold(_tokenId, seller, msg.sender, msg.value);
    }

    /**
     * @dev Liste une place de parking pour la vente
     */
    function listParkingSpot(uint256 _tokenId, uint256 _newPrice) public {
        require(ownerOf(_tokenId) == msg.sender, "Vous n'etes pas le proprietaire");
        require(_newPrice > 0, "Le prix doit etre superieur a 0");
        
        ParkingSpot storage spot = parkingSpots[_tokenId];
        spot.price = _newPrice;
        spot.isAvailable = true;
        
        emit ParkingSpotListed(_tokenId, _newPrice, true);
    }

    /**
     * @dev Retire une place de parking de la vente
     */
    function unlistParkingSpot(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Vous n'etes pas le proprietaire");
        
        ParkingSpot storage spot = parkingSpots[_tokenId];
        spot.isAvailable = false;
        
        emit ParkingSpotListed(_tokenId, spot.price, false);
    }

    /**
     * @dev Récupère tous les tokens d'un propriétaire
     */
    function getOwnerTokens(address _owner) public view returns (uint256[] memory) {
        return ownerTokens[_owner];
    }

    /**
     * @dev Récupère les détails d'une place de parking
     */
    function getParkingSpot(uint256 _tokenId) public view returns (ParkingSpot memory) {
        require(_exists(_tokenId), "Ce token n'existe pas");
        return parkingSpots[_tokenId];
    }

    /**
     * @dev Modifie les frais de plateforme (seulement le propriétaire)
     */
    function setPlatformFee(uint256 _newFee) public onlyOwner {
        require(_newFee <= 10, "Les frais ne peuvent pas depasser 10%");
        platformFee = _newFee;
    }

    /**
     * @dev Modifie l'adresse de collecte des frais (seulement le propriétaire)
     */
    function setFeeCollector(address _newCollector) public onlyOwner {
        require(_newCollector != address(0), "Adresse invalide");
        feeCollector = _newCollector;
    }

    /**
     * @dev Fonction interne pour retirer un token de la liste d'un propriétaire
     */
    function _removeTokenFromOwner(address _owner, uint256 _tokenId) private {
        uint256[] storage tokens = ownerTokens[_owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    // Fonctions requises par Solidity

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}