<?php

namespace App\Tests\Support;

use PHPUnit\Framework\MockObject\MockObject;
use Symfony\Bundle\FrameworkBundle\KernelBrowser;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use Symfony\Contracts\HttpClient\ResponseInterface;

trait HttpClientMockTrait
{
    private HttpClientInterface&MockObject $mockHttpClient;
    private ResponseInterface&MockObject $mockResponse;

    protected function setUpHttpClientMocks(): void
    {
        $this->mockHttpClient = $this->createMock(HttpClientInterface::class);
        $this->mockResponse = $this->createMock(ResponseInterface::class);
    }

    /**
     * Configure HTTP client mock for a single request
     */
    protected function mockHttpRequest(
        string $method, 
        string $url, 
        array $options = [], 
        int $statusCode = 200, 
        array $responseData = []
    ): void {
        $this->mockHttpClient->expects($this->once())
            ->method('request')
            ->with($method, $url, $options)
            ->willReturn($this->mockResponse);
            
        $this->mockResponse->expects($this->once())
            ->method('getStatusCode')
            ->willReturn($statusCode);
            
        if (!empty($responseData)) {
            $this->mockResponse->expects($this->once())
                ->method('toArray')
                ->willReturn($responseData);
        }
    }

    /**
     * Create client with mocked HTTP client
     */
    protected function createClientWithMockedHttpClient(): KernelBrowser
    {
        $client = static::createClient();
        $client->getContainer()->set('http_client', $this->mockHttpClient);
        return $client;
    }
}
