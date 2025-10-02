<?php

namespace App\Tests\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Symfony\Component\HttpFoundation\Response;

class HomeControllerTest extends WebTestCase
{
    public function testIndexRedirectsToUsersList(): void
    {
        $client = static::createClient();
        $client->request('GET', '/');

        $this->assertResponseRedirects('/users');
        $this->assertResponseStatusCodeSame(Response::HTTP_FOUND);
    }

    public function testIndexRoute(): void
    {
        $client = static::createClient();
        $client->request('GET', '/');

        $this->assertResponseRedirects('/users');
        
        // Sprawdź czy routing działa poprawnie
        $this->assertRouteSame('home');
    }
}
