import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Req,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiParam } from '@nestjs/swagger';
import { AddressesService } from './addresses.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';

@ApiTags('Addresses')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('addresses')
export class AddressesController {
  constructor(private readonly addressesService: AddressesService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new address' })
  async create(@Body() dto: CreateAddressDto, @Req() req: any) {
    const address = await this.addressesService.create(req.user.id, dto);
    return { success: true, data: address };
  }

  @Get()
  @ApiOperation({ summary: 'List my addresses' })
  async findAll(@Req() req: any) {
    const addresses = await this.addressesService.findAll(req.user.id);
    return { success: true, data: addresses };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get address by id' })
  @ApiParam({ name: 'id', description: 'Address ID' })
  async findOne(@Param('id', ParseUUIDPipe) id: string, @Req() req: any) {
    const address = await this.addressesService.findOne(id, req.user.id);
    return { success: true, data: address };
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update an address' })
  @ApiParam({ name: 'id', description: 'Address ID' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAddressDto,
    @Req() req: any,
  ) {
    const address = await this.addressesService.update(id, req.user.id, dto);
    return { success: true, data: address };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete an address' })
  @ApiParam({ name: 'id', description: 'Address ID' })
  async remove(@Param('id', ParseUUIDPipe) id: string, @Req() req: any) {
    await this.addressesService.remove(id, req.user.id);
    return { success: true };
  }
}
