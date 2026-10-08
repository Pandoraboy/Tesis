<?php

namespace App\Services;

use Google\Client;
use Illuminate\Auth\AuthenticationException;
use LogicException;
use UnexpectedValueException;

class GoogleIdentityService
{
    public function __construct(
        private Client $client
    ) {}

    public function verificar(string $idToken): array
    {
        $clientId = config('services.google.web_client_id');

        if (! is_string($clientId) || trim($clientId) === '') {
            throw new LogicException(
                'Falta configurar GOOGLE_WEB_CLIENT_ID.'
            );
        }

        if (trim($idToken) === '') {
            throw new AuthenticationException(
                'No se pudo verificar la cuenta de Google.'
            );
        }

        $this->client->setClientId($clientId);

        try {
            $datos = $this->client->verifyIdToken($idToken);
        } catch (UnexpectedValueException $exception) {
            throw new AuthenticationException(
                'No se pudo verificar la cuenta de Google.'
            );
        }

        if (
            ! is_array($datos)
            || ($datos['aud'] ?? null) !== $clientId
            || ! in_array(
                $datos['iss'] ?? null,
                ['accounts.google.com', 'https://accounts.google.com'],
                true
            )
            || ! is_int($datos['exp'] ?? null)
            || $datos['exp'] <= time()
            || ! is_string($datos['sub'] ?? null)
            || trim($datos['sub']) === ''
            || strlen($datos['sub']) > 255
        ) {
            throw new AuthenticationException(
                'No se pudo verificar la cuenta de Google.'
            );
        }

        // Los contactos se validarán al crear la cuenta.
        // Para una identidad ya vinculada, el identificador es sub.
        return [
            'subject' => $datos['sub'],
            'email' => is_string($datos['email'] ?? null)
                ? strtolower(trim($datos['email']))
                : null,
            'email_verified' => ($datos['email_verified'] ?? false) === true,
        ];
    }
}