import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/ticket.dart';

final myTicketsProvider = FutureProvider.autoDispose<List<Ticket>>((ref) async {
  final res = await DioClient.instance.get('/tickets');
  final data = res.data['data'] as List;
  return data.map((json) => Ticket.fromJson(json)).toList();
});

final ticketDetailProvider = FutureProvider.autoDispose.family<Ticket, int>((ref, id) async {
  final res = await DioClient.instance.get('/tickets/$id');
  return Ticket.fromJson(res.data);
});
