<?php

namespace Tests\Unit;

use App\Services\GoogleIdentityService;
use Google\Client;
use Illuminate\Auth\AuthenticationException;
use Mockery;
use Tests\TestCase;

class GoogleIdentityServiceTest extends TestCase
{
    private function servicio(array|false $respuesta): GoogleIdentityService
    {
        config([
            'services.google.web_client_id' => 'cliente-prueba',
        ]);

        $client = Mockery::mock(Client::class);

        $client->shouldReceive('setClientId')
            ->once()
            ->with('cliente-prueba');

        $client->shouldReceive('verifyIdToken')
            ->once()
            ->with('credencial-de-prueba')
            ->andReturn($respuesta);

        return new GoogleIdentityService($client);
    }

    private function datosValidos(): array
    {
        return [
            'aud' => 'cliente-prueba',
            'iss' => 'https://accounts.google.com',
            'exp' => time() + 3600,
            'sub' => 'google-usuario-123',
            'email' => ' Persona@Example.com ',
            'email_verified' => true,
        ];
    }

    public function test_devuelve_identidad_verificada(): void
    {
        $servicio = $this->servicio($this->datosValidos());

        $resultado = $servicio->verificar('credencial-de-prueba');

        $this->assertSame([
            'subject' => 'google-usuario-123',
            'email' => 'persona@example.com',
            'email_verified' => true,
        ], $resultado);
    }

    public function test_rechaza_credencial_no_verificada(): void
    {
        $servicio = $this->servicio(false);

        $this->expectException(AuthenticationException::class);

        $servicio->verificar('credencial-de-prueba');
    }

    public function test_rechaza_credencial_de_otra_aplicacion(): void
    {
        $datos = $this->datosValidos();
        $datos['aud'] = 'otra-aplicacion';

        $servicio = $this->servicio($datos);

        $this->expectException(AuthenticationException::class);

        $servicio->verificar('credencial-de-prueba');
    }

    public function test_rechaza_emisor_incorrecto(): void
    {
        $datos = $this->datosValidos();
        $datos['iss'] = 'https://otro-emisor.example.com';

        $servicio = $this->servicio($datos);

        $this->expectException(AuthenticationException::class);

        $servicio->verificar('credencial-de-prueba');
    }

    public function test_rechaza_credencial_vencida(): void
    {
        $datos = $this->datosValidos();
        $datos['exp'] = time() - 60;

        $servicio = $this->servicio($datos);

        $this->expectException(AuthenticationException::class);

        $servicio->verificar('credencial-de-prueba');
    }

    public function test_rechaza_identidad_sin_identificador(): void
    {
        $datos = $this->datosValidos();
        unset($datos['sub']);

        $servicio = $this->servicio($datos);

        $this->expectException(AuthenticationException::class);

        $servicio->verificar('credencial-de-prueba');
    }
}