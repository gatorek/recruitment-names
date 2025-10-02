<?php

namespace App\Exception;

use InvalidArgumentException;

class InvalidUserIdException extends InvalidArgumentException
{
    public function __construct(string $id)
    {
        parent::__construct("Invalid user ID '{$id}'. Please provide a valid positive number.");
    }
}
