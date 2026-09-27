import 'package:intl/intl.dart';

import '../domain/domain.dart';

/// Price wording for the paywall. Prices are framed the way people weigh
/// them on holiday: per month, per person, per day of the trip.

String formatPrice(double amount, String currencyCode) =>
    NumberFormat.simpleCurrency(name: currencyCode).format(amount);

/// "$34.99".
String priceOf(Offer offer) => formatPrice(offer.amount, offer.currencyCode);

/// "$2.92" a month for an annual plan.
String perMonth(Offer offer) => formatPrice(offer.amount / 12, offer.currencyCode);

/// "$0.49" a person a month, for the whole family on an annual plan.
String perPersonPerMonth(Offer offer) =>
    formatPrice(offer.amount / 12 / Pricing.familySize, offer.currencyCode);

/// "$1.14" a day for a Trip Pass on a trip of [days] days.
String perDay(Offer offer, int days) =>
    formatPrice(offer.amount / (days < 1 ? 1 : days), offer.currencyCode);
