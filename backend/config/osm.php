<?php

return [
    // Catálogo inicial. Otras etiquetas quedan conservadas en el JSON fuente.
    'categorias' => [
        'amenity' => [
            'restaurant' => 'Comida y cafeterías', 'cafe' => 'Comida y cafeterías',
            'fast_food' => 'Comida y cafeterías', 'ice_cream' => 'Comida y cafeterías',
            'bar' => 'Comida y cafeterías', 'pub' => 'Comida y cafeterías',
            'pharmacy' => 'Salud', 'doctors' => 'Salud', 'clinic' => 'Salud',
            'hospital' => 'Salud', 'dentist' => 'Salud', 'veterinary' => 'Mascotas',
            'school' => 'Educación', 'kindergarten' => 'Educación',
            'college' => 'Educación', 'university' => 'Educación',
            'library' => 'Cultura y comunidad', 'community_centre' => 'Cultura y comunidad',
            'arts_centre' => 'Cultura y comunidad', 'theatre' => 'Cultura y comunidad',
            'place_of_worship' => 'Cultura y comunidad', 'studio' => 'Cultura y comunidad',
            'bank' => 'Servicios', 'post_office' => 'Servicios',
            'car_rental' => 'Transporte y vehículos', 'fuel' => 'Transporte y vehículos',
            'bus_station' => 'Transporte y vehículos', 'taxi' => 'Transporte y vehículos',
            'vehicle_inspection' => 'Transporte y vehículos',
            'marketplace' => 'Comercio',
            'police' => 'Servicios públicos', 'fire_station' => 'Servicios públicos',
            'townhall' => 'Servicios públicos', 'courthouse' => 'Servicios públicos',
        ],
        'tourism' => [
            'hotel' => 'Alojamiento', 'motel' => 'Alojamiento',
            'guest_house' => 'Alojamiento', 'hostel' => 'Alojamiento',
            'museum' => 'Cultura y comunidad', 'attraction' => 'Turismo',
            'information' => 'Turismo', 'artwork' => 'Cultura y comunidad',
        ],
        'leisure' => [
            'park' => 'Parques y recreación', 'playground' => 'Parques y recreación',
            'sports_centre' => 'Deporte', 'fitness_centre' => 'Deporte',
            'sports_hall' => 'Deporte', 'stadium' => 'Deporte',
            'pitch' => 'Deporte', 'horse_riding' => 'Deporte',
        ],
        'shop' => ['*' => 'Comercio'],
        'office' => ['government' => 'Servicios públicos', '*' => 'Servicios'],
        'craft' => ['*' => 'Oficios'],
    ],
];
