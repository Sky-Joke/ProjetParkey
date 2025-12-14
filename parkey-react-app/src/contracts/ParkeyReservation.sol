// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IParkeyNFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getParkingSpot(uint256 tokenId) external view returns (
        string memory parkingAddress,
        string memory parkingType,
        string memory size,
        uint256 price,
        bool isAvailable,
        bool available247,
        address currentOwner,
        uint256 createdAt
    );
}

interface IParkeyEscrow {
    function createPayment(
        address _payer,
        address _payee,
        uint256 _releaseTime,
        string memory _reference,
        bool _autoRelease
    ) external payable returns (uint256);
    
    function refundPayment(uint256 _paymentId) external;
    function releasePayment(uint256 _paymentId) external;
    function getPaymentByReference(string memory _reference) external view returns (
        uint256 paymentId,
        address payer,
        address payee,
        uint256 amount,
        uint256 releaseTime,
        uint256 createdAt,
        uint8 status,
        string memory ref,
        bool autoRelease
    );
}

/**
 * @title ParkeyReservation
 * @dev Gestion des réservations temporaires avec intégration Escrow
 */
contract ParkeyReservation is Ownable, ReentrancyGuard {
    IParkeyNFT public parkeyNFT;
    IParkeyEscrow public parkeyEscrow;
    
    // Structure d'une réservation
    struct Reservation {
        uint256 reservationId;
        uint256 tokenId;
        uint256 escrowPaymentId;    // ID du paiement dans l'escrow
        address owner;
        address renter;
        uint256 startTime;
        uint256 endTime;
        uint256 totalPrice;
        uint256 pricePerHour;
        bool isActive;
        bool isCompleted;
        bool isCancelled;
        uint256 createdAt;
    }
    
    // Structure pour les tarifs de location
    struct RentalListing {
        uint256 pricePerHour;
        uint256 pricePerDay;
        uint256 minDuration; // en heures
        uint256 maxDuration; // en heures
        bool isAvailable;
        bool autoAccept; // Acceptation automatique ou validation manuelle
    }
    
    // Mappings
    mapping(uint256 => RentalListing) public rentalListings;
    mapping(uint256 => Reservation) public reservations;
    mapping(uint256 => uint256[]) public tokenReservations;
    mapping(address => uint256[]) public userReservations;
    
    // Compteurs
    uint256 public reservationCounter;
    
    // Frais de plateforme pour les réservations (1%)
    uint256 public reservationFee = 1;
    address public feeCollector;
    
    // Durées par défaut
    uint256 public constant DEFAULT_MIN_DURATION = 1; // 1 heure
    uint256 public constant DEFAULT_MAX_DURATION = 720; // 30 jours
    
    // Events
    event RentalListingCreated(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 pricePerHour,
        uint256 pricePerDay
    );
    
    event RentalListingUpdated(
        uint256 indexed tokenId,
        uint256 pricePerHour,
        uint256 pricePerDay,
        bool isAvailable
    );
    
    event ReservationCreated(
        uint256 indexed reservationId,
        uint256 indexed tokenId,
        uint256 escrowPaymentId,
        address indexed renter,
        uint256 startTime,
        uint256 endTime,
        uint256 totalPrice
    );
    
    event ReservationCompleted(
        uint256 indexed reservationId,
        uint256 indexed tokenId,
        uint256 escrowPaymentId
    );
    
    event ReservationCancelled(
        uint256 indexed reservationId,
        uint256 indexed tokenId,
        address cancelledBy,
        uint256 refundAmount
    );

    constructor(address _parkeyNFTAddress, address _parkeyEscrowAddress) Ownable(msg.sender) {
        require(_parkeyNFTAddress != address(0), "Adresse NFT invalide");
        require(_parkeyEscrowAddress != address(0), "Adresse Escrow invalide");
        
        parkeyNFT = IParkeyNFT(_parkeyNFTAddress);
        parkeyEscrow = IParkeyEscrow(_parkeyEscrowAddress);
        feeCollector = msg.sender;
    }

    /**
     * @dev Le propriétaire d'un NFT met sa place en location
     */
    function createRentalListing(
        uint256 _tokenId,
        uint256 _pricePerHour,
        uint256 _pricePerDay,
        uint256 _minDuration,
        uint256 _maxDuration,
        bool _autoAccept
    ) external {
        require(parkeyNFT.ownerOf(_tokenId) == msg.sender, "Vous n'etes pas le proprietaire");
        require(_pricePerHour > 0, "Le prix horaire doit etre superieur a 0");
        require(_pricePerDay > 0, "Le prix journalier doit etre superieur a 0");
        require(_minDuration >= 1, "Duree minimum: 1 heure");
        require(_maxDuration > _minDuration, "Duree max doit etre superieure a la min");
        
        rentalListings[_tokenId] = RentalListing({
            pricePerHour: _pricePerHour,
            pricePerDay: _pricePerDay,
            minDuration: _minDuration,
            maxDuration: _maxDuration,
            isAvailable: true,
            autoAccept: _autoAccept
        });
        
        emit RentalListingCreated(_tokenId, msg.sender, _pricePerHour, _pricePerDay);
    }

    /**
     * @dev Mettre à jour un listing de location
     */
    function updateRentalListing(
        uint256 _tokenId,
        uint256 _pricePerHour,
        uint256 _pricePerDay,
        bool _isAvailable
    ) external {
        require(parkeyNFT.ownerOf(_tokenId) == msg.sender, "Vous n'etes pas le proprietaire");
        require(rentalListings[_tokenId].pricePerHour > 0, "Listing inexistant");
        
        RentalListing storage listing = rentalListings[_tokenId];
        listing.pricePerHour = _pricePerHour;
        listing.pricePerDay = _pricePerDay;
        listing.isAvailable = _isAvailable;
        
        emit RentalListingUpdated(_tokenId, _pricePerHour, _pricePerDay, _isAvailable);
    }

    /**
     * @dev Créer une réservation avec paiement en escrow
     */
    function createReservation(
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _endTime
    ) external payable nonReentrant {
        RentalListing memory listing = rentalListings[_tokenId];
        require(listing.isAvailable, "Cette place n'est pas disponible a la location");
        require(_startTime >= block.timestamp, "La date de debut doit etre dans le futur");
        require(_endTime > _startTime, "La date de fin doit etre apres le debut");
        
        // Vérifier la durée
        uint256 durationHours = (_endTime - _startTime) / 3600;
        require(durationHours >= listing.minDuration, "Duree trop courte");
        require(durationHours <= listing.maxDuration, "Duree trop longue");
        
        // Vérifier les conflits
        require(!_hasConflict(_tokenId, _startTime, _endTime), "Conflit avec une reservation existante");
        
        // Calculer le prix
        uint256 totalPrice = _calculatePrice(listing, durationHours);
        require(msg.value >= totalPrice, "Paiement insuffisant");
        
        address owner = parkeyNFT.ownerOf(_tokenId);
        uint256 reservationId = reservationCounter++;
        
        // Créer la référence unique pour l'escrow
        string memory escrowReference = string(abi.encodePacked("RES-", _uint2str(reservationId)));
        
        // Créer le paiement en escrow
        uint256 escrowPaymentId = parkeyEscrow.createPayment{value: totalPrice}(
            msg.sender,      // payer (locataire)
            owner,           // payee (propriétaire)
            _endTime,        // releaseTime (fin de réservation)
            escrowReference, // référence unique
            true            // autoRelease activé
        );
        
        // Créer la réservation
        reservations[reservationId] = Reservation({
            reservationId: reservationId,
            tokenId: _tokenId,
            escrowPaymentId: escrowPaymentId,
            owner: owner,
            renter: msg.sender,
            startTime: _startTime,
            endTime: _endTime,
            totalPrice: totalPrice,
            pricePerHour: listing.pricePerHour,
            isActive: true,
            isCompleted: false,
            isCancelled: false,
            createdAt: block.timestamp
        });
        
        tokenReservations[_tokenId].push(reservationId);
        userReservations[msg.sender].push(reservationId);
        
        emit ReservationCreated(reservationId, _tokenId, escrowPaymentId, msg.sender, _startTime, _endTime, totalPrice);
        
        // Rembourser l'excédent
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    /**
     * @dev Calculer le prix d'une réservation
     */
    function _calculatePrice(RentalListing memory listing, uint256 durationHours) internal pure returns (uint256) {
        // Si durée >= 24h, utiliser le tarif journalier
        if (durationHours >= 24) {
            uint256 numDays = durationHours / 24;
            uint256 remainingHours = durationHours % 24;
            return (numDays * listing.pricePerDay) + (remainingHours * listing.pricePerHour);
        }
        
        // Sinon, tarif horaire
        return durationHours * listing.pricePerHour;
    }

    /**
     * @dev Vérifier les conflits de réservation
     */
    function _hasConflict(uint256 _tokenId, uint256 _start, uint256 _end) internal view returns (bool) {
        uint256[] memory reservationIds = tokenReservations[_tokenId];
        
        for (uint256 i = 0; i < reservationIds.length; i++) {
            Reservation memory res = reservations[reservationIds[i]];
            
            // Ignorer les réservations annulées ou terminées
            if (res.isCancelled || res.isCompleted) continue;
            
            // Vérifier le chevauchement
            if ((_start >= res.startTime && _start < res.endTime) ||
                (_end > res.startTime && _end <= res.endTime) ||
                (_start <= res.startTime && _end >= res.endTime)) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * @dev Compléter une réservation et libérer les fonds de l'escrow
     */
    function completeReservation(uint256 _reservationId) external nonReentrant {
        Reservation storage reservation = reservations[_reservationId];
        
        require(reservation.isActive, "Reservation non active");
        require(!reservation.isCompleted, "Reservation deja terminee");
        require(!reservation.isCancelled, "Reservation annulee");
        require(block.timestamp >= reservation.endTime, "La reservation n'est pas encore terminee");
        require(
            msg.sender == reservation.renter || 
            msg.sender == reservation.owner ||
            msg.sender == owner(),
            "Non autorise"
        );
        
        // Marquer comme complétée
        reservation.isCompleted = true;
        reservation.isActive = false;
        
        // Libérer le paiement de l'escrow
        parkeyEscrow.releasePayment(reservation.escrowPaymentId);
        
        emit ReservationCompleted(_reservationId, reservation.tokenId, reservation.escrowPaymentId);
    }

    /**
     * @dev Annuler une réservation (avant son début)
     */
    function cancelReservation(uint256 _reservationId) external nonReentrant {
        Reservation storage reservation = reservations[_reservationId];
        
        require(reservation.isActive, "Reservation non active");
        require(!reservation.isCompleted, "Reservation deja terminee");
        require(!reservation.isCancelled, "Reservation deja annulee");
        require(
            msg.sender == reservation.renter || msg.sender == reservation.owner,
            "Non autorise"
        );
        
        // Politique d'annulation : impossible d'annuler après le début
        if (block.timestamp >= reservation.startTime) {
            revert("Impossible d'annuler apres le debut");
        }
        
        // Marquer comme annulée
        reservation.isCancelled = true;
        reservation.isActive = false;
        
        // Calculer le remboursement
        uint256 refundAmount;
        
        // Si annulation < 24h avant : frais de 10%
        if (reservation.startTime - block.timestamp < 86400) {
            refundAmount = (reservation.totalPrice * 90) / 100;
            
            // Les 10% restants vont au propriétaire via l'escrow
            // On ne peut pas faire de remboursement partiel avec l'escrow actuel
            // Donc on rembourse tout et on gère les frais ici
            parkeyEscrow.refundPayment(reservation.escrowPaymentId);
            
            // Envoyer les frais d'annulation au propriétaire
            uint256 cancellationFee = reservation.totalPrice - refundAmount;
            payable(reservation.owner).transfer(cancellationFee);
        } else {
            // Remboursement complet
            refundAmount = reservation.totalPrice;
            parkeyEscrow.refundPayment(reservation.escrowPaymentId);
        }
        
        emit ReservationCancelled(_reservationId, reservation.tokenId, msg.sender, refundAmount);
    }

    /**
     * @dev Obtenir toutes les réservations d'un token
     */
    function getTokenReservations(uint256 _tokenId) external view returns (uint256[] memory) {
        return tokenReservations[_tokenId];
    }

    /**
     * @dev Obtenir toutes les réservations d'un utilisateur
     */
    function getUserReservations(address _user) external view returns (uint256[] memory) {
        return userReservations[_user];
    }

    /**
     * @dev Vérifier la disponibilité d'une place
     */
    function checkAvailability(
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _endTime
    ) external view returns (bool) {
        if (!rentalListings[_tokenId].isAvailable) return false;
        return !_hasConflict(_tokenId, _startTime, _endTime);
    }

    /**
     * @dev Calculer le prix d'une réservation potentielle
     */
    function calculateReservationPrice(
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _endTime
    ) external view returns (uint256) {
        RentalListing memory listing = rentalListings[_tokenId];
        require(listing.isAvailable, "Place non disponible");
        
        uint256 durationHours = (_endTime - _startTime) / 3600;
        require(durationHours >= listing.minDuration, "Duree trop courte");
        require(durationHours <= listing.maxDuration, "Duree trop longue");
        
        return _calculatePrice(listing, durationHours);
    }

    /**
     * @dev Obtenir les détails d'un listing de location
     */
    function getRentalListing(uint256 _tokenId) external view returns (RentalListing memory) {
        return rentalListings[_tokenId];
    }

    /**
     * @dev Obtenir les détails complets d'une réservation
     */
    function getReservationDetails(uint256 _reservationId) external view returns (Reservation memory) {
        return reservations[_reservationId];
    }

    /**
     * @dev Modifier l'adresse de l'escrow (owner only)
     */
    function setEscrowAddress(address _newEscrowAddress) external onlyOwner {
        require(_newEscrowAddress != address(0), "Adresse invalide");
        parkeyEscrow = IParkeyEscrow(_newEscrowAddress);
    }

    /**
     * @dev Modifier les frais de réservation (owner only)
     */
    function setReservationFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 5, "Les frais ne peuvent pas depasser 5%");
        reservationFee = _newFee;
    }

    /**
     * @dev Modifier l'adresse de collecte des frais (owner only)
     */
    function setFeeCollector(address _newCollector) external onlyOwner {
        require(_newCollector != address(0), "Adresse invalide");
        feeCollector = _newCollector;
    }

    /**
     * @dev Fonction utilitaire pour convertir uint en string
     */
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Récupérer les fonds coincés (owner only - urgence uniquement)
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Fonction pour recevoir les ETH (pour les frais d'annulation)
     */
    receive() external payable {}
}